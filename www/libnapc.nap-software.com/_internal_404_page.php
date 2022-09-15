<?php

require_once __DIR__."/lib/getLatestReleaseVersion.php";

$latest_version = libnapc_getLatestReleaseVersion();

echo file_get_contents(
	__DIR__."/$latest_version/404.html"
);
