$(function() {

    $('a[class=void-link]').click(function(event) {
        event.preventDefault();
    });

    $('.disable_enter_key').keypress(function (event) {
        var code = event.charCode || event.keyCode;
        if (code == 13) return false;
    });

    $('.saint-alert').each(function() {
        var alert = $(this).html();
        if (alert.length > 0)
            Saint.alert(alert);
    });

    $("a[rel=tooltip]").tooltip();

    $('.saint-ui-chosen').chosen({
        allow_single_deselect: true
    });
    $(".saint-selectable").hover(
        function () {
            $(this).addClass("saint-selectable-hover");
        },
        function () {
            $(this).removeClass("saint-selectable-hover");
        }
    );
    $(".saint-selectable").click(
        function () {
            $(this).toggleClass("saint-selectable-selected");
        }
    );

    var win = $(window);
    var is_fixed = 0;
    var element = $('.adaptive-nav').first();
    var element_offset = element.offset();
    if (element_offset) {
        var fix_at = element_offset.top - 40;
        var adaptive_nav = function() {
            var top = win.scrollTop();
            if (top >= fix_at && is_fixed == 0) {
                is_fixed = 1;
                element.addClass('adaptive-nav-fixed');
            } else if (top <= fix_at && is_fixed == 1) {
                is_fixed = 0;
                element.removeClass('adaptive-nav-fixed');
            }
        };
        adaptive_nav();
        win.on('scroll', adaptive_nav);
    }
});
