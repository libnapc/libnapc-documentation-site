<?php
require_once __DIR__."/lib/getLatestReleaseVersion.php";

$uri = $_SERVER["REQUEST_URI"];
$uri = substr($uri, strlen("/latest/"));
$clean_uri = str_replace("\n", "", $uri);

$latest_version = libnapc_getLatestReleaseVersion();

header("Location: https://libnapc.nap-software.com/$latest_version/$clean_uri");
