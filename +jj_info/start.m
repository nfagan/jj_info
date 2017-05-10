function err = start()

try
  opts = jj_info.setup();
catch err
  jj_info.cleanup();
  jj_info.util.print_error_stack( err );
  return;
end

try
  err = 0;
  jj_info.task( opts );
  jj_info.cleanup();
catch err
  jj_info.cleanup();
  jj_info.util.print_error_stack( err );
end

end