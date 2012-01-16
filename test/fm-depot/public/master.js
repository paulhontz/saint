$(function() {

    $("ul.saint-menu-top").superfish();

});

function SaintClass() {

    this.GET_request = function(url) {
        $.get(url);
    }

    this.valid_get = function(url, success_callback_or_container_id, error_callback_or_container_id) {

        $.get(
            url,
            function(response) {

                var status = 0;
                var error = null;
                try {
                    status = response.status;
                    error = response.error;
                } catch (e) {
                    alert(e);
                    return false;
                }

                if (status == 0) { // error handling

                    if (typeof(error_callback_or_container_id) === 'function') {
                        return error_callback_or_container_id.call(this, error);
                    }
                    var alert = error;
                    var update_container_id = error_callback_or_container_id;

                } else { // success handling

                    if (typeof(success_callback_or_container_id) === 'function') {
                        return success_callback_or_container_id.call(this, status);
                    }
                    var alert = status;
                    var update_container_id = success_callback_or_container_id;
                }

                var update_container = $("#" + update_container_id);
                if (jQuery.isEmptyObject(update_container)) return false;

                update_container.html(alert);
                Saint.ui_alert(update_container);

            },
            'json'
        );
    }

    this.submit_form = function(form_id, update_container_id, request_method) {

        var form = $("#" + form_id);
        if (jQuery.isEmptyObject(form)) return false;

        var action = form.attr("action");
        if (jQuery.isEmptyObject(action)) return false;

        if (jQuery.isEmptyObject(request_method)) {
            var method = "GET";
        } else {
            var method = request_method.toUpperCase();
        }

        $.ajax({
            type: method,
            url: action,
            data: form.serialize(),
            success: function(response) {
                // there are cases we need to submit a form
                // without updating any container.
                // in such cases we just return true.
                var container = $("#" + update_container_id);
                if (jQuery.isEmptyObject(container)) return true;
                container.html(response);
            }
        });
    }

    this.submit_valid_form = function(form_id, error_container_id, callback_or_redirect_url_prefix, redirect_url_suffix) {

        var errors = "";

        var form = $("#" + form_id);
        if (jQuery.isEmptyObject(form))
            errors += "form not found. ";
        else {
            var action = form.attr("action");
            if (jQuery.isEmptyObject(action))
                errors += "form action attribute is empty. ";
        }

        var error_container = $("#" + error_container_id);
        if (jQuery.isEmptyObject(error_container))
            errors += "error container not found. ";

        if (errors.length > 0) {
            alert(errors);
            return false;
        }

        $.post(
            action,
            form.serialize(),
            function(response) {

                var status = 0;
                var error = null;
                var alert = null;
                try {
                    status = response.status;
                    error = response.error;
                    alert = response.alert;
                } catch (e) {
                    alert(e);
                    return false;
                }

                if (typeof(callback_or_redirect_url_prefix) === 'undefined')
                    return response;

                if (status > 0) {

                    if (typeof(callback_or_redirect_url_prefix) === 'function')
                        return callback_or_redirect_url_prefix.call(this, status);

                    var redirect_url = callback_or_redirect_url_prefix + status;
                    if (typeof(redirect_url_suffix) === 'string')
                        redirect_url += redirect_url_suffix;

                    window.location = redirect_url;

                } else {
                    error_container.html(error);
                    Saint.ui_alert(error_container);
                    return false;
                }
            },
            'json'
        );
    }

    this.update_container = function(container_id, url) {

        var container = $("#" + container_id);
        if (jQuery.isEmptyObject(container)) return false;

        if (jQuery.isEmptyObject(url)) {
            container.html('');
            return true;
        }

        $.get(
            url,
            function(response) {
                container.html(response);
            }
        );
    }

    this.update_value = function(element_id, value) {

        var element = $("#" + element_id);
        if (jQuery.isEmptyObject(element)) return false;

        if (jQuery.isEmptyObject(value)) {
            element.remove();
        }

        element.attr("value", value);
    }

    this.pager = function(url, container_id) {
        $.get(
            url,
            function(response) {
                $("#" + container_id).html(response);
            }
        );
    }

    this.ui_alert = function(container, alert) {

        if (jQuery.isEmptyObject(container)) return false;
        if (jQuery.isEmptyObject(alert))
            alert = container.html();
        else
            container.html(alert);

        if (jQuery.isEmptyObject(alert)) return false;

        if (alert.length == 0) return false;

        if (alert.match(/saint\-errors_dialog_container/)) {
            container.dialog({
                title: "Operation failed with errors:",
                modal: true,
                minWidth: 500,
                minHeight: 200
            });
        } else {
            container.show(
                "pulsate",
                1000,
                function() {
                    $(this).hide();
                }
            );
        }
    }

    this.utilsClass = function() {

        this.toggleChildrenContainer = function(container_id) {

            var container = $('#' + container_id);
            var status_container = $('#' + container_id + '-status');
            if (jQuery.isEmptyObject(container)) return false;
            if (jQuery.isEmptyObject(status_container)) return false;

            container.toggle();
            if (container.is(":visible")) {
                status_container.html('children <strong>-</strong>');
            } else {
                status_container.html('children <strong>+</strong>');
            }
        }
    }
    this.Utils = new this.utilsClass();
}

Saint = new SaintClass();
