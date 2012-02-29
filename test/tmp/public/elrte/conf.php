<?php

define("APP_ROOT",      realpath( dirname( __FILE__ ) ) . "/" );

define("BASEURL", "/" );

define("HELPERS_PATH",  APP_ROOT . "helpers/" );
define("DEPOT_PATH",    APP_ROOT . "depot/"   );
define("PUBLIC_PATH",   APP_ROOT . "public/"  );

define("FFMPEG_BIN", "/opt/local/bin/ffmpeg");
define("DEFAULT_VIDEO_RESOLUTION", "480x360" );

$tmp = explode("x", DEFAULT_VIDEO_RESOLUTION);
define("DEFAULT_VIDEO_WIDTH",  $tmp[0]);
define("DEFAULT_VIDEO_HEIGHT", $tmp[1]);
