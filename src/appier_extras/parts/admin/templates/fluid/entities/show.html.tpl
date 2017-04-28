{% extends "admin/admin.fluid.html.tpl" %}
{% block title %}{{ entity }}{% endblock %}
{% block name %}{{ entity }}{% endblock %}
{% block buttons %}
    {{ super() }}
    <ul class="drop-down views force" data-name="Views">
        {% for view in model.views() %}
            {% set view_valid = not view.devel or own.is_devel() %}
            {% if view.instance and view_valid %}
                {% if view.parameters %}
                    <li>
                        <a class="button" data-window_open="#window-{{ view.method }}">{{ view.name }}</a>
                    </li>
                {% else %}
                    <li>
                        <a href="{{ url_for('admin.view_model', model = model._under(), view = view.method, id = entity._id) }}">{{ view.name }}</a>
                    </li>
                {% endif %}
            {% endif %}
        {% endfor %}
    </ul>
    <ul class="drop-down links force" data-name="Links">
        {% for link in model.links() %}
            {% set link_valid = not link.devel or own.is_devel() %}
            {% if link.instance and link_valid %}
                {% if link.parameters %}
                    <li>
                        <a class="button" data-window_open="#window-{{ link.method }}">{{ link.name }}</a>
                    </li>
                {% else %}
                    <li>
                        <a class="no-async" target="_blank"
                           href="{{ url_for('admin.link_model', model = model._under(), link = link.method, ids = entity._id) }}">{{ link.name }}</a>
                    </li>
                {% endif %}
            {% endif %}
        {% endfor %}
    </ul>
    <ul class="drop-down operations force" data-name="Operations">
        {% for operation in model.operations() %}
            {% set operation_valid = not operation.devel or own.is_devel() %}
            {% if operation.instance and operation_valid %}
                {% if operation.parameters %}
                    <li>
                        <a class="button" data-window_open="#window-{{ operation.method }}">{{ operation.name }}</a>
                    </li>
                {% else %}
                    {% if operation.level > 1 %}
                        <li>
                            <a href="{{ url_for('admin.operation_model', model = model._under(), operation = operation.method, ids = entity._id, next = location_f) }}"
                               class="link-confirm" data-message="Are you sure you want to [[{{ operation.name }}]] ?">{{ operation.name }}</a>
                        </li>
                    {% else %}
                        <li>
                            <a href="{{ url_for('admin.operation_model', model = model._under(), operation = operation.method, ids = entity._id, next = location_f) }}">{{ operation.name }}</a>
                        </li>
                    {% endif %}
                {% endif %}
            {% endif %}
        {% endfor %}
    </ul>
    <div class="button button-color button-grey"
         data-link="{{ url_for('admin.edit_entity', model = model._under(), _id = entity._id) }}">Edit</div>
{% endblock %}
{% block windows %}
    {{ super() }}
    {% for link in model.links() %}
        {% if link.parameters %}
            <div id="window-{{ link.method }}" class="window window-link">
                <h1>{{ link.name }}</h1>
                <form class="form" method="post" enctype="multipart/form-data"
                      action="{{ url_for('admin.link_model', model = model._under(), link = link.method, ids = entity._id) }}">
                    {% for parameter in link.parameters %}
                        {% set label, name, data_type = parameter[:3] %}
                        {% set default = parameter[3] if parameter|length > 3 else "" %}
                        <label>{{ label }}</label>
                        {{ tag_input_b("parameters", value = default, type = data_type) }}
                    {% endfor %}
                    <div class="window-buttons">
                        <span class="button button-cancel close-button">Cancel</span>
                        <span class="button button-confirm" data-submit="1">Confirm</span>
                    </div>
                </form>
            </div>
        {% endif %}
    {% endfor %}
    {% for operation in model.operations() %}
        {% if operation.parameters %}
            <div id="window-{{ operation.method }}" class="window window-operation">
                <h1>{{ operation.name }}</h1>
                <form class="form" method="post" enctype="multipart/form-data"
                      action="{{ url_for('admin.operation_model', model = model._under(), operation = operation.method, ids = entity._id, next = location_f) }}">
                    {% for parameter in operation.parameters %}
                        {% set label, name, data_type = parameter[:3] %}
                        {% set default = parameter[3] if parameter|length > 3 else "" %}
                        <label>{{ label }}</label>
                        {{ tag_input_b("parameters", value = default, type = data_type) }}
                    {% endfor %}
                    <div class="window-buttons">
                        <span class="button button-cancel close-button">Cancel</span>
                        <span class="button button-confirm" data-submit="1">Confirm</span>
                    </div>
                </form>
            </div>
        {% endif %}
    {% endfor %}
{% endblock %}
{% block content %}
    <div class="shortcuts">
        <div class="key" data-key="76" data-url="{{ url_for('admin.show_model', model = model._under()) }}"></div>
        <div class="key" data-key="69" data-url="{{ url_for('admin.edit_entity', model = model._under(), _id = entity._id) }}"></div>
        {% if previous_url %}<div class="previous-url hidden">{{ previous_url }}</div>{% endif %}
        {% if next_url %}<div class="next-url hidden">{{ next_url }}</div>{% endif %}
    </div>
    <div class="show-panel">
        <div class="panel-contents simple">
            <dl class="inline">
                {% for name in model.show_names() %}
                    {% set description = model.to_description(name) %}
                    {% set observations = model.to_observations(name) %}
                    <div class="item">
                        <dt>
                            {% if observations %}
                                <div class="balloon balloon-observations">
                                    <span class="baloon-icon">{{ description }}</span>
                                    <div class="balloon-contents">{{ observations }}</div>
                                </div>
                            {% else%}
                                <span>{{ description }}</span>
                            {% endif %}
                        </dt>
                        <dd>{{ out(entity, name) }}</dd>
                    </div>
                {% endfor %}
            </dl>
        </div>
    </div>
{% endblock %}
