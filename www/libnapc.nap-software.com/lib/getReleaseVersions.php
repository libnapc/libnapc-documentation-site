<?php

require_once __DIR__."/parseVersionNumber.php";

function libnapc_getReleaseVersions() {
	$entries = scandir(__DIR__."/../");

	$versions = array_filter($entries, function($item) {
		return is_dir(__DIR__."/../$item") && substr($item, 0, 1) === "v";
	});

	usort($versions, function($a, $b) {
		$a = libnapc_parseVersionNumber($a);
		$b = libnapc_parseVersionNumber($b);

		if ($a > $b) return -1;

		return 1;
	});

	return $versions;
}
