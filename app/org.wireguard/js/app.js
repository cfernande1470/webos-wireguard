@@
-const APPDIR = "/media/developer/apps/usr/palm/applications/org.webosbrew.wireguard";
+const APPDIR = "/media/developer/apps/usr/palm/applications/org.wireguard";
@@
-  const cmd =
-    "APPID='org.webosbrew.wireguard'; " +
+  const cmd =
+    "APPID='org.wireguard'; " +
@@
-      "INSTALL=$(find /media -type f -path '*/org.webosbrew.wireguard/payload/wireguard/install.sh' 2>/dev/null | head -1); " +
+      "INSTALL=$(find /media -type f -path '*/org.wireguard/payload/wireguard/install.sh' 2>/dev/null | head -1); " +
@@
-      "find /media -path '*org.webosbrew.wireguard*' 2>/dev/null | head -120; " +
+      "find /media -path '*org.wireguard*' 2>/dev/null | head -120; " +
@@
-    "if (toggle) {
+    "if (toggle) {
       toggle.checked = false;
       toggle.disabled = true;
     }
   });
 }
