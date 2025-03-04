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

{# This macro exists to help bridge between the dbt-core get_create_*_as macros and doris's implementations #}

{% macro get_create_unique_table_as_sql(temporary, relation, sql) %}
  {{ return(adapter.dispatch('create_unique_table_as', 'dbt')(temporary, relation, sql)) }}
{% endmacro %}

{% macro default__create_unique_table_as(temporary, relation, sql) %}
  {# fallback for adapters without unique table support #}
  {{ return(create_table_as(temporary, relation, sql)) }}
{% endmacro %} 