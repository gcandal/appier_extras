{% extends "admin/admin.fluid.html.tpl" %}
{% block title %}{{ entity }} / {{ definition.name }}{% endblock %}
{% block name %}
    <a href="{{ url_for('admin.show_entity', model = model._name(), _id = entity._id) }}">
        {{ entity }}
    </a>/
    <span>{{ definition.name }}</span>
{% endblock %}
{% block style %}no-padding{% endblock %}
{% block content %}
    <table class="filter bulk" data-no_input="1" data-size="{{ page.size }}"
           data-total="{{ page.total }}" data-pages="{{ page.count }}">
        <thead>
            <tr class="table-row table-header">
                <th class="text-left selection">
                    <input type="checkbox" class="square small" />
                </th>
                {% for name in names or model.list_names() %}
                    {% set description = target.to_description(name) %}
                    {% if name == page.sorter %}
                        <th class="text-left direction {{ page.direction }}">
                            <a href="{{ page.query(sorter = name) }}">{{ description }}</a>
                        </th>
                    {% else %}
                        <th class="text-left">
                            <a href="{{ page.query(sorter = name) }}">{{ description }}</a>
                        </th>
                    {% endif %}
                {% endfor %}
            </tr>
        </thead>
        <tbody class="filter-contents">
            {% for entity in entities %}
                <tr class="table-row" data-id="{{ entity._id }}">
                    <td class="text-left selection">
                        <input type="checkbox" class="square small" />
                    </td>
                    {% for name in names or target.list_names() %}
                        {% if loop.first %}
                            <td class="text-left">
                                <a href="{{ url_for('admin.show_entity', model = target._name(), _id = entity._id) }}">
                                    {{ out(entity, name) }}
                                </a>
                            </td>
                        {% else %}
                            <td class="text-left">{{ out(entity, name) }}</td>
                        {% endif %}
                    {% endfor %}
                </tr>
            {% endfor %}
        </tbody>
    </table>
    {% if page.count > 1 %}
        {{ paging(page.index, page.count, caller = page.query) }}
    {% endif %}
{% endblock %}
