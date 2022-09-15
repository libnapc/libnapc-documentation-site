<?php

require_once __DIR__."/getReleaseVersions.php";

function libnapc_getLatestReleaseVersion() {
	$versions = libnapc_getReleaseVersions();

	return $versions[0];
}
