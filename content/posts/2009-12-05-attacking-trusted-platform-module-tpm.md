+++
title = "Attacking Trusted Platform Module (TPM)"
author = "Victor"
date = "2009-12-05"
tags = ["hacking", "security"]
category = "blog"
+++

For those of who believe that using authenticated boot features such as TPM should protect you against hackers... : WRONG! In their latest project some guys from Frauenhofer SIT (Security Test Lab) have managed to conduct a quite realistic attack against a Windows machine with BitLocker, the disk encryption functionality in most recent Windows versions. As stated [here][1] there is a video which demonstrates a proof-of-concept implementation of such an attack. Using a fake boot screen which was previously installed in the MBR, the attacker can spoof the user interaction of BitLocker and obtain the secret key (PIN) from the user, write this to disk and reboot the machine. Afterwards the original boot screen is reinstalled and the user doesnt have a clue what happened. So do NOT leave your laptop unattended whereever you are! View full video [here][2].

 [1]: http://testlab.sit.fraunhofer.de/content/output/project_results/bitlocker_skimming/
 [2]: http://testlab.sit.fraunhofer.de/content/output/project_results/bitlocker_skimming/bitlockervideo.php?s=2
