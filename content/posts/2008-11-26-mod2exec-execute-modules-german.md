+++
title = "Mod2Exec - Execute modules "
date = "2008-11-26"
tags = ["coding", "security", "vx", "linux", "kernel", "german"]
category = "blog"
+++

## Einleitung

Wir leben in einer Zeit, in der Dynamik sowie Flexibilität eine große Rolle spielen. Wir alle besitzen bestimmte Fähigkeiten, die in bestimmten Situationen zum Einsatz kommen können. Das heißt, der Mensch braucht diese nur zur richtigen Zeit „aufzurufen“. Genauso soll ein Kernel, das Herzstück eines Betriebssystems, auch funktionieren: Die aktuelle  
Systemkonfiguration wird überprüft und Module werden hochgeladen. Damit werden dem Kernel Schnittstellen zur Verfügung gestellt, die zur Steuerung der Hardware etc. dienen. Das statische Kompilieren von Modulen in den Kernel erfreut sich heutzutage keiner großen Beliebtheit, da Prozessorleistung und Ressourcen darunter leiden. Außerdem muss der Kernel nicht jedes Mal neu „gebacken“ werden, wenn man zu der aktuellen Kernel-Konfiguration Features hinzufügen/deaktivieren möchte.

Dieser Artikel befasst sich mit einer neuen Technik, die dazu verwendet wird, aus Modulen ausführbare Dateien zu erzeugen, die die Fähigkeit besitzen, sich selbst in den Kernel  
hochzuladen. Dabei muss man tief in die Arbeitsweise jener Dateien, die am Prozess des Hochladens beteiligt sind, blicken, sowie die unterschiedlichen Typen und Strukturen des  
Binärformats ELF (Executable and Linking Format) genau untersuchen. Darauf wird jedoch an einer anderen Stelle im Artikel Bezug genommen.

Viel Spaß beim Lesen!
