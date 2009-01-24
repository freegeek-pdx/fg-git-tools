<?php
$cmdline = "/home/ryan52/request-mirror-update " . $_GET["type"] . " " . $_GET["project"];
#echo $cmdline;
system($cmdline);
?>
