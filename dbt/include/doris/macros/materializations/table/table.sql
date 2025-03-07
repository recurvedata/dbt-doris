-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements. See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership. The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License. You may obtain a copy of the License at
--
-- http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing,
-- software distributed under the License is distributed on an
-- "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
-- KIND, either express or implied. See the License for the
-- specific language governing permissions and limitations
-- under the License.

{% materialization table, adapter='doris' %}

  {%- set existing_relation = load_cached_relation(this) -%}
  {%- set target_relation = this.incorporate(type='table') %}
  {%- set intermediate_relation =  make_intermediate_relation(target_relation) -%}
  {%- set preexisting_intermediate_relation = load_cached_relation(intermediate_relation) -%}

  -- grab current tables grants config for comparision later on
  {% set grant_config = config.get('grants') %}

  -- Execute pre-hooks before anything else
  {{ run_hooks(pre_hooks, inside_transaction=False) }}
  {{ run_hooks(pre_hooks, inside_transaction=True) }}

  -- drop the temp relations if they exist already in the database
  {{ doris__drop_relation(preexisting_intermediate_relation) }}

  -- Check if this is a Unique Table by looking for unique_key config
  {% set is_unique_table = config.get('unique_key', none) is not none %}

  -- build model
  {% call statement('main') -%}
    {% if is_unique_table %}
      {{ get_create_unique_table_as_sql(False, intermediate_relation, sql) }}
    {% else %}
      {{ get_create_table_as_sql(False, intermediate_relation, sql) }}
    {% endif %}
  {%- endcall %}

  {% if existing_relation -%}
    {% do exchange_relation(target_relation, intermediate_relation, True) %}
  {% else %}
    {{ adapter.rename_relation(intermediate_relation, target_relation) }}
  {% endif %}


  {% set should_revoke = should_revoke(existing_relation, full_refresh_mode=True) %}
  {% do apply_grants(target_relation, grant_config, should_revoke=should_revoke) %}

  -- alter relation comment
  {% do persist_docs(target_relation, model) %}

  -- finally, drop the existing/backup relation after the commit
  {{ doris__drop_relation(intermediate_relation) }}

  -- Execute post-hooks inside transaction
  {{ run_hooks(post_hooks, inside_transaction=True) }}
  
  -- Commit the transaction
  {% do adapter.commit() %}
  
  -- Execute post-hooks outside transaction
  {{ run_hooks(post_hooks, inside_transaction=False) }}

  {{ return({'relations': [target_relation]}) }}
{% endmaterialization %}
