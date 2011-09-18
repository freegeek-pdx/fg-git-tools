<?php
// $array = array('fgwebsite', 'continuation', 'fg-git-tools', 'fgdb.rb', 'fgdiag', 'freegeek-extras', 'freegeek-ubuntu-pocket-guide', 'rubytui', 'wxKeyboardTester', 'commit-cruncher', 'reusewebsite', 'schedule', 'vote', 'techsupporttools');
$array = preg_split("/[\s,]+/", file_get_contents("/git/allowed_list"));
if(!in_array($_GET["project"], $array)) exit();
if(!in_array($_GET["type"], array('git', 'svn'))) exit();
$cmdline = "/home/ryan52/request-mirror-update " . $_GET["type"] . " " . $_GET["project"];
system($cmdline);
?>
