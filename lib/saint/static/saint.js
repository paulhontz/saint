$(function() {

    $("ul.sf-menu").supersubs({
        minWidth: 10,
        maxWidth: 20,
        extraWidth: 1
    }).superfish({delay: 200});

});

function SaintClass() {

    this.GET_request = function(url) {
        $.get(url);
    }

    this.valid_get = function(url, success_callback, error_callback) {

        $.get(
            url,
            function(response) {

                var status = 0;
                var message = null;
                try {
                    status = response.status;
                    message = response.message;
                } catch (e) {
                    alert(e);
                    return false;
                }

                if (status == 0) { // error handling

                    if (typeof(error_callback) === 'function')
                        return error_callback.call(this, response);

                } else { // success handling

                    if (typeof(success_callback) === 'function')
                        return success_callback.call(this, response);
                }

                Saint.ui_alert(message);

            },
            'json'
        );
    }

    this.submit_form = function(form_id, update_container_id, request_method) {

        var form = $("#" + form_id);
        if (jQuery.isEmptyObject(form)) return false;

        var action = form.attr("action");
        if (jQuery.isEmptyObject(action)) return false;

        var method = null;

        if (jQuery.isEmptyObject(request_method))
            method = "GET";
        else
            method = request_method.toUpperCase();

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

                // updating given container
                container.html(response);
            }
        });
    }

    this.submit_valid_form = function(form_id, success_callback, error_callback) {

        var errors = '';

        var form = $("#" + form_id);
        if (jQuery.isEmptyObject(form))
            errors += "form not found. ";
        else {
            var action = form.attr("action");
            if (jQuery.isEmptyObject(action))
                errors += "form action attribute is empty. ";
        }

        if (errors.length > 0) {
            Saint.ui_alert(errors)
            return false;
        }

        $.post(
            action,
            form.serialize(),
            function(response) {

                var status = 0;
                var message = null;
                try {
                    status = response.status;
                    message = response.message;
                } catch (e) {
                    alert(e);
                    return false;
                }

                if (status == 0) { // error handling

                    if (typeof(error_callback) === 'function')
                        return error_callback.call(this, response);

                } else { // success handling

                    if (typeof(success_callback) === 'function')
                        return success_callback.call(this, response);
                }

                Saint.ui_alert(message);
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

    this.ui_alert = function(alert, opts) {

        if (jQuery.isEmptyObject(alert)) return false;
        if (alert.length == 0) return false;

        opts = opts || {};
        opts.title = opts.title || alert.match(/saint\-errors_dialog_container/) ? 'Operation failed with errors' : 'Success';
        opts.time = opts.time || 5000;
        opts.text = alert;

        $.gritter.add(opts);
    }

    this.FmClass = function() {
        this.display_file = function(url) {
            var c = $('#saint-fm-file_window');
            $.get(url, function(response) {
                $(c).html(response)
                $(c).addClass('modal');
                $(c).modal();
            });
        }

        this.create_item = function(form_id, item_type) {
            $('#' + form_id + '-type').val(item_type);
            Saint.submit_valid_form(form_id, function(response) {
                window.location = response.location
            });
        }
    }
    this.Fm = new this.FmClass();

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
