<?php

function libnapc_parseVersionNumber($str) {
	list($a, $b, $c) = explode(".", substr($str, 1), 3);

	$a = (int)$a;
	$b = (int)$b;
	$c = (int)$c;

	return ($a * 100) + ($b * 10) + ($c * 1);
}
