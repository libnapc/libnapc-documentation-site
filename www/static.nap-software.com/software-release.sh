#!/usr/bin/env php
<?php

#
# This script gets executed after the github workflow process got initialized.
# The workflow script does the following things before invoking this script:
# - Place the SSH github key to a predetermined location
# - Install any dependencies needed to build libnapc
# - Clone the linux release, arduino release repository and documentation release repository
# - Remove any files from those repositories (except the .git folder)
#

fwrite(STDERR, "Using software-release.sh: ".hash_file("sha256", __FILE__)." (sha256)\n");

function bail($message) {
	fwrite(STDERR, "$message\n");
	exit(1);
}

function assert_readenv($env_name) {
	$value = getenv($env_name);

	if (!$value) {
		bail("Failed to read environment variable '$env_name'");
	}

	return $value;
}

function assert_write_file($file, $contents) {
	$bytes_written = file_put_contents($file, $contents);

	if (strlen($contents) !== $bytes_written) {
		bail("Failed to write file '$file'");
	}
}

function assert_system_call($cmd) {
	system($cmd, $exit_code);

	if ($exit_code !== 0) {
		exit($exit_code);
	}
}

function assert_chdir($path) {
	if (!chdir($path)) {
		bail("Failed to cd() to '$path'");
	}
}

function assert_sha256_file($file) {
	$hash = hash_file("sha256", $file);

	if (!$hash) {
		bail("Failed to hash file '$file'");
	}

	return $hash;
}

if (sizeof($argv) !== 2) {
	bail("Usage: software-release.sh <tag-name>");
}

# Valid formats:
# v1.0.0 -> means version 1.0.0 (stable)
$git_tag = $argv[1];

if (substr($git_tag, 0, 1) !== "v") {
	bail("git tag does not start with 'v': $git_tag");
}

$current_user = exec("whoami");

define("LIBNAPC_GITHUB_SSH_KEY_PATH", "/home/$current_user/github-deploy.key");
define("LIBNAPC_DEPLOY_SSH_KEY_PATH", "/home/$current_user/deploy.key");
define("LIBNAPC_ARDUINO_RELEASES_GIT_PATH", "/home/$current_user/libnapc-arduino-releases/");
define("LIBNAPC_LINUX_RELEASES_GIT_PATH", "/home/$current_user/libnapc-linux-releases/");
define("LIBNAPC_DOCUMENTATION_GIT_PATH", "/home/$current_user/libnapc-documentation/");
define("LIBNAPC_VERSION", substr($git_tag, 1));
define("LIBNAPC_GIT_PATH", realpath(getcwd()));
define("CURRENT_USER", $current_user);

if (!is_file(LIBNAPC_GITHUB_SSH_KEY_PATH)) {
	bail("GITHUB_SSH_KEY_PATH '".LIBNAPC_GITHUB_SSH_KEY_PATH."' does not exist.");
} else if (!is_file(LIBNAPC_DEPLOY_SSH_KEY_PATH)) {
	bail("LIBNAPC_DEPLOY_SSH_KEY_PATH '".LIBNAPC_DEPLOY_SSH_KEY_PATH."' does not exist.");
}

function upload_to_remote_host($src_path, $dst_path) {
	$upload_username = assert_readenv("LIBNAPC_DEPLOY_USER");
	$upload_hostname = assert_readenv("LIBNAPC_DEPLOY_HOST");

	$scp_source        = escapeshellarg($src_path);
	$scp_identity_file = escapeshellarg(LIBNAPC_DEPLOY_SSH_KEY_PATH);
	$scp_destination   = escapeshellarg(
		"$upload_username@$upload_hostname:$dst_path"
	);

	$scp_flags = "-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null";

	assert_system_call("scp $scp_flags -i $scp_identity_file $scp_source $scp_destination");
}

function remote_execute_command($cmd) {
	$username = assert_readenv("LIBNAPC_DEPLOY_USER");
	$hostname = assert_readenv("LIBNAPC_DEPLOY_HOST");

	$ssh_flags = "-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null";
	$ssh_identity_file = escapeshellarg(LIBNAPC_DEPLOY_SSH_KEY_PATH);
	$ssh_host = escapeshellarg("$username@$hostname");
	$ssh_cmd = escapeshellarg($cmd);

	assert_system_call("ssh $ssh_flags -i $ssh_identity_file $ssh_host -- $ssh_cmd");
}

function git_commit() {
	# branch has 'v' prefix like v1.2.3
	assert_system_call("git checkout -b v".LIBNAPC_VERSION);
	assert_system_call("git add .");
	assert_system_call("git commit -m 'Release ".LIBNAPC_VERSION."' -S");
	# tag name without "v" for arduino library registry
	assert_system_call("git tag -a ".LIBNAPC_VERSION." -m 'Release ".LIBNAPC_VERSION."' --sign");
	# push branch
	assert_system_call("git push -u origin v".LIBNAPC_VERSION);
	# push tag
	assert_system_call("git push origin ".LIBNAPC_VERSION);
}

# Run the CI script
assert_system_call("LIBNAPC_RELEASE_VERSION=v".LIBNAPC_VERSION." ./.napci/run.sh");

#####################################
# Deployment to linux-releases repo #
#####################################
(function() {
	assert_chdir(LIBNAPC_LINUX_RELEASES_GIT_PATH);
	$libnapc_linux_release_tar = LIBNAPC_GIT_PATH."/.napci/build_files/bundles/linux.tar.gz";
	$libnapc_header_file = LIBNAPC_GIT_PATH."/.napci/build_files/processed_files/napc.h";
	assert_system_call("cp ".escapeshellarg($libnapc_linux_release_tar)." libnapc-linux-v".LIBNAPC_VERSION.".tar.gz");
	assert_system_call("cp ".escapeshellarg($libnapc_header_file)." napc.h");
	git_commit();
})();

#######################################
# Deployment to arduino-releases repo #
#######################################
(function() {
	assert_chdir(LIBNAPC_ARDUINO_RELEASES_GIT_PATH);
	$libnapc_arduino_zip = LIBNAPC_GIT_PATH."/.napci/build_files/bundles/arduino.zip";
	# Unpack arduino library release (zip archive)
	assert_system_call("unzip ".escapeshellarg($libnapc_arduino_zip)." -d .");
	git_commit();
})();

####################################
# Deployment to documentation repo #
####################################
(function() {
	assert_chdir(LIBNAPC_DOCUMENTATION_GIT_PATH);
	$libnapc_documentation_tar = LIBNAPC_GIT_PATH."/.napci/build_files/documentation.tar.gz";
	# Unpack documentation (tarball)
	assert_system_call("tar -xzvf ".escapeshellarg($libnapc_documentation_tar)." -C .");
	git_commit();
})();

####################################################
# Upload documentation to libnapc.nap-software.com #
####################################################
(function() {
	assert_chdir("/home/".CURRENT_USER."/");

	$libnapc_version = LIBNAPC_VERSION;

	$upload_files = [
		"tmp/libnapc-documentation-v$libnapc_version.tar.gz" => LIBNAPC_GIT_PATH."/.napci/build_files/documentation.tar.gz",
		"tmp/libnapc-linux-v$libnapc_version.tar.gz" => LIBNAPC_GIT_PATH."/.napci/build_files/bundles/linux.tar.gz",
		"tmp/libnapc-arduino-v$libnapc_version.zip" => LIBNAPC_GIT_PATH."/.napci/build_files/bundles/arduino.zip",
		"tmp/libnapc-v$libnapc_version.h" => LIBNAPC_GIT_PATH."/.napci/build_files/processed_files/napc.h"
	];

	$check_integrity_script = "#!/bin/bash -euf\n";

	foreach ($upload_files as $destination => $source) {
		$sha256_hash = assert_sha256_file($source);
		$destination_basename = basename($destination);

		$check_integrity_script .= "printf \"Checking $destination_basename ... \"\n";
		$check_integrity_script .= "printf \"$sha256_hash $destination_basename\" | sha256sum --check --status\n";
		$check_integrity_script .= "printf \"ok\\n\"\n";
	}

	$check_integrity_script .= "printf \"Successfully checked integrity!\\n\"\n";

	assert_write_file("check-integrity.sh", $check_integrity_script);

	foreach ($upload_files as $destination => $source) {
		fwrite(STDERR, "Uploading ".basename($source)."\n");

		upload_to_remote_host($source, $destination);
	}

	upload_to_remote_host("check-integrity.sh", "tmp/check-integrity-v$libnapc_version.sh");

	$upload_username = assert_readenv("LIBNAPC_DEPLOY_USER");

	$install_script = "#!/bin/bash -eufx\n";
	$install_script .= <<<SCRIPT
cd /home/$upload_username/www/
rm -rf v$libnapc_version/
rm -rf v$libnapc_version.tmp/
mkdir v$libnapc_version.tmp/
cd v$libnapc_version.tmp/

mv ../../tmp/libnapc-documentation-v$libnapc_version.tar.gz .
mv ../../tmp/libnapc-linux-v$libnapc_version.tar.gz .
mv ../../tmp/libnapc-arduino-v$libnapc_version.zip .
mv ../../tmp/libnapc-v$libnapc_version.h .
mv ../../tmp/check-integrity-v$libnapc_version.sh .

chmod +x check-integrity-v$libnapc_version.sh

./check-integrity-v$libnapc_version.sh
rm ./check-integrity-v$libnapc_version.sh

tar -xzvf libnapc-documentation-v$libnapc_version.tar.gz -C .

mkdir download

mv libnapc-linux-v$libnapc_version.tar.gz download/libnapc-linux.tar.gz
mv libnapc-arduino-v$libnapc_version.zip download/libnapc-arduino.zip
mv libnapc-v$libnapc_version.h download/napc.h

rm libnapc-documentation-v$libnapc_version.tar.gz

cd ..

mv v$libnapc_version.tmp v$libnapc_version

rm -f symlink-to-latest-version
ln -s v$libnapc_version symlink-to-latest-version

rm ../tmp/install-v$libnapc_version.sh
SCRIPT;

	assert_write_file("install.sh", $install_script);
	upload_to_remote_host("install.sh", "tmp/install-v$libnapc_version.sh");

	remote_execute_command("chmod +x tmp/install-v$libnapc_version.sh");
	remote_execute_command("./tmp/install-v$libnapc_version.sh");
})();
