<?php
/**
 * Cobot OAuth Callback Script
 */

// NOTE: This script is not really that secure. Don't leave it up any longer than you have to.

$oauth_token = filter_input(INPUT_GET, 'oauth_token', FILTER_SANITIZE_STRING);
$oauth_verifier = filter_input(INPUT_GET, 'oauth_verifier', FILTER_SANITIZE_STRING);

echo "OAuth Token: <span class=\"oauth-token\">" . $oauth_token . "</span><br />";
echo "OAuth Verifier: <span class=\"oauth-secret\">" . $oauth_secret . "</span>";
?>
