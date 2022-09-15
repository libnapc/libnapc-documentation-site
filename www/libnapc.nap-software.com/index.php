<?php
require_once __DIR__."/lib/getReleaseVersions.php";

$versions = libnapc_getReleaseVersions();

if (isset($_POST["version"])) {
	$requested_version = $_POST["version"];

	if (in_array($requested_version, $versions)) {
		header("Location: https://libnapc.nap-software.com/$requested_version/");
		exit();
	}
}

$entries = [];

foreach ($versions as $version) {
	list($major, $minor, $bugfix) = explode(".", $version, 3);

	if (!array_key_exists("$major.$minor.x", $entries)) {
		$entries["$major.$minor.x"] = "$major.$minor.$bugfix";
	}
}
?>
<!DOCTYPE html>
<html>
<head>
	<meta charset="utf-8">
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<title>libnapc</title>
</head>
<body>

	<style>
		* {
			padding: 0;
			margin: 0;
			box-sizing: border-box;
		}

		body, html {
			width: 100%;
			height: 100%;
			color: white;
			font-family: Arial;
			font-size: 14px;
		}

		body {
			display: flex;
			align-items: center;
			justify-content: center;
			background: #111119;
			flex-direction: column;
		}

		#libnapc-logo {
			flex-grow: 0; flex-shrink: 0;
			width: 400px;
			height: 90px;
			background: url("https://static.nap-software.com/github/libnapc/logo-plain-white.png");
			background-size: auto 100%;
			background-position: center;
			background-repeat: no-repeat;
			margin-bottom: 15px;
		}

		#content {
			flex-grow: 0; flex-shrink: 0;
			width: 400px;
			height: 200px;
			/*
			background: #09080E;
			border-radius: 4px;
			box-shadow: 0px 16px 13px 1px rgba(255, 255, 255, 0.01);
			*/
			padding: 25px 50px;
		}

		#content form {
			display: flex;
			align-items: center;
			justify-content: center;
			flex-direction: column;
		}

		#content h1 {
			font-size: 17px;
			margin-bottom: 15px;
		}

		#content select {
			margin: 10px 0px;
			outline: none;
		}

		#content button {
			background-image: linear-gradient(15deg, #00A366, #0093F9);
			background-color: #00A366;
			border: none;
			color: white;
			display: flex;
			align-items: center;
			justify-content: center;
			padding: 8px 16px;
			margin-top: 25px;
			border-radius: 20px;
			text-shadow: 0px 2px 2px rgba(9, 8, 14, .35);
		}

		#napsw-logo {
			flex-grow: 0; flex-shrink: 0;
			width: 400px;
			height: 25px;
			background: url("https://static.nap-software.com/logo.png");
			background-size: auto 100%;
			background-position: center;
			background-repeat: no-repeat;
			margin-top: 15px;
		}

		@media only screen and (max-width: 600px)  {
			#libnapc-logo { width: 100%; }
			#content { width: 100%; }
			#napsw-logo { width: 100%; }
		}
	</style>

	<div id="libnapc-logo"></div>
	<div id="content">
		<form action="https://libnapc.nap-software.com/" method="post">
			<h1>Welcome!</h1>
			<p>Please select a version:</p>
			<select name="version">
				<?php
					$index = 0;

					foreach ($entries as $version_label => $exact_version) {
						$label = "";

						if ($index === 0) $label = " (latest)";

						echo "<option value=\"$exact_version\">$version_label$label</option>";

						++$index;
					}
				?>
			</select>
			<button type="submit">Open documentation</button>
		</form>
	</div>
	<div id="napsw-logo"></div>
</body>
</html>

