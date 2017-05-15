function assert__is_valid_path( str )

try
  orig = cd;
  cd( str );
  cd( orig );
catch
  error( '\n The path ''%s'' is invalid', str );
end

end