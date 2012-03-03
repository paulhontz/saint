$(function() {

    $("ul.sf-menu").supersubs({
        minWidth: 10,
        maxWidth: 20,
        extraWidth: 1
    }).superfish({delay: 200});

});

function SaintClass() {

    this.request = function(type, url, data, callback) {
        $.ajax({
            type: type,
            url: url,
            data: data,
            success: callback,
            error: function(r) {
                alert('request failed with error: ' + r);
            }
        });
    }

    this.valid_request = function(type, url, data, success_callback, error_callback) {

        $.ajax({
            type: type,
            url: url,
            data: data,
            dataType: 'json',
            success: function(response) {

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

                Saint.alert(message);

            },
            error: function(jqXHR) {
                Saint.alert(jqXHR);
            }
        });
    }

    this.valid_GET = function(url, success_callback, error_callback) {
        return this.valid_request('GET', url, {}, success_callback, error_callback);
    }

    this.valid_POST = function(url, data, success_callback, error_callback) {
        return this.valid_request('POST', url, data, success_callback, error_callback);
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
            Saint.alert(errors)
            return false;
        }

        this.valid_request('POST', action, form.serialize(), success_callback, error_callback);
    }

    this.update_container = function(container_id, url_or_opts) {

        var container = $("#" + container_id);
        if (jQuery.isEmptyObject(container)) return false;

        var type = 'GET', url, data = {}, form;
        if (typeof url_or_opts == 'object') {
            type = url_or_opts.type;
            url = url_or_opts.url;
            data = url_or_opts.data;
            if (form = url_or_opts.form) {
                form = $('#' + form);
                type = type || form.attr('method');
                url = url || form.attr('action');
                data = data || form.serialize();
            }
        } else
            url = url_or_opts;

        this.request(type, url, data, function(response) {
            container.html(response)
        });
    }

    this.empty_container = function(container_id) {
        var container = $("#" + container_id);
        if (jQuery.isEmptyObject(container)) return false;
        container.empty();
    }

    this.update_value = function(element_id, value) {

        var element = $("#" + element_id);
        if (jQuery.isEmptyObject(element)) return false;

        if (jQuery.isEmptyObject(value)) {
            element.remove();
        }

        element.attr("value", value);
    }

    this.reset_form = function(form_id){
        document.getElementById(form_id).reset();
        $(".saint-ui-chosen").val('').trigger('liszt:updated');
    }

    this.alert = function(alert, opts) {

        if (jQuery.isEmptyObject(alert)) return false;
        if (alert.length == 0) return false;

        opts = opts || {};
        opts.title = opts.title || alert.match(/saint\-errors_dialog_container/) ? 'Operation failed with errors' : 'Success';
        opts.time = opts.time || 5000;
        opts.text = alert;

        $.gritter.add(opts);
    }

    this.FmClass = function() {

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
