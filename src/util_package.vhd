library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package util_package is    
    function clog2 (x : POSITIVE) return POSITIVE;
    function maximum(x : INTEGER; y : INTEGER) return INTEGER;
    function minimum(x : INTEGER; y : INTEGER) return INTEGER;
    function get_valid_kind(array_size : POSITIVE; matrix_line : POSITIVE) return POSITIVE;
    -- Add your own code here
end util_package;

package body util_package is

function clog2 (x : POSITIVE) return POSITIVE is
    variable i : POSITIVE;
begin
    i := 1;  
    while (2**i < x) and i < 31 loop
        i := i + 1;
    end loop;
    return i;
end function;

function maximum(x : INTEGER; y : INTEGER) return INTEGER is
    variable z : INTEGER;
begin
    if x > y then
        z := x;
    else
        z := y;
    end if;
    return z;
end function;

function minimum(x : INTEGER; y : INTEGER) return INTEGER is
    variable z : INTEGER;
begin
    if x > y then
        z := y;
    else
        z := x;
    end if;
    return z;
end function;

function get_valid_kind(array_size : POSITIVE; matrix_line : POSITIVE) return POSITIVE is
    variable i : POSITIVE;
begin
    i := 1;
    while (matrix_line*i < 2*array_size-1) and i < 31 loop
        i := i + 1;
    end loop;
    return i;
end function;

-- Add your own code here

end package body util_package;