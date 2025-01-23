;; magit can be really slow in linux trees if you have too many features enabled!
((magit-status-mode
  ; Inserting tags in the main refresh window is slow
  . ((eval . (magit-disable-section-inserter 'magit-insert-tags-header))))

 (magit-revision-mode
  ; magit-revision-insert-related-refs takes over 18 seconds on Linux commits.
  ; Disabling reduces time to view commit from >18s to ~90ms. This turns off
  ; seeing this stuff when looking at a specific commit:
  ;
  ; Parent:     f5bcd8d37e90 kernfs: Add splice_read to struct file_operations
  ; Merged:     master
  ; Contained:  davidreaver/port-tracefs-kernfs
  ; Follows:    v6.13 (4756)
  . ((eval . (setq magit-revision-insert-related-refs nil)))))
