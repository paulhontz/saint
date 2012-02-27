$(function() {
    $(".saint-button").button();
    $(".saint-ui-resizable").resizable();
    $(".saint-ui-resizable-horizontal").resizable({
        handles: 'w,e'
    });
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
    $(".saint-tabs").tabs({
        cookie: {}
    });
    $(".saint-tabs-no_cookies").tabs();
});
