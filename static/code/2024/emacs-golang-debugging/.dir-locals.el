((go-mode . ((dape-configs . (
   ;; Beginning of debug profiles
      ;; Profile 1: Launch application and start DAP server
      (go-debug-taskapi
        modes (go-mode go-ts-mode)
        command "dlv"
        command-args ("dap" "--listen" "127.0.0.1:55878")
        command-cwd default-directory
        host "127.0.0.1"
        port 55878
        :request "launch"
        :mode "debug"
        :type "go"
        :showLog "true"
        :program ".")
       ;; Profile 2: Attach to external debugger   
       (go-attach-taskapi
        modes (go-mode go-ts-mode)
        command "dlv"
        command-cwd default-directory
        host "127.0.0.1"   ;; can also be skipped
        port 55878
        :request "attach"  ;; this will run "dlv attach ..."  
        :mode "remote"     ;; connect to a running debugger session
        :type "go"
        :showLog "true")
       ;; Profile 3: Attach to running process (by PID)
       (go-attach-pid
        modes (go-mode go-ts-mode)
        command "dlv"
        command-args ("dap" "--listen" "127.0.0.1:55878" "--log")
        command-cwd default-directory
        host "127.0.0.1"   
        port 55878
        :request "attach"  
        :mode "local"      ;; Attach to a running process local to the server     
        :type "go"
        :processId (+get-process-id-by-name "taskapi")
        :showLog "true")
       ;; Profile 4: Debug Ginkgo tests
       (go-test-ginkgo
        modes (go-mode go-ts-mode)
        command "dlv"
        command-args ("dap" "--listen" "127.0.0.1:55878" "--log")
        command-cwd default-directory
        host "127.0.0.1"   
        port 55878
        :request "launch"  
        :mode "test"      ;; Debug tests
        :type "go"
        :args ["-ginkgo.v" "-ginkgo.focus" "should create and return a task with an ID"]
        :program ".")
   ))
   ;; End of dape-configs

   ;; Helper functions
        ;; Add helpful function 
        (eval . (progn
                  (defun +get-process-id-by-name (process-name)
                    "Return the process ID of a process specified by PROCESS-NAME. Works on Unix-like systems (Linux, MacOS)."
                    (interactive)
                    (let ((pid nil))
                      (cond
                       ((memq system-type '(gnu/linux darwin))
                        (setq pid (shell-command-to-string 
                                   (format "pgrep -f %s" 
                                           (shell-quote-argument process-name)))))
                       (t
                        (error "Unsupported system type: %s" system-type)))
   
                      ;; Clean up the output and return first PID
                      (when (and pid (not (string-empty-p pid)))
                        (car (split-string pid "\n" t)))))))
)))
