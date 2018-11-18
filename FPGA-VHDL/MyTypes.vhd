--------------------------------------------------------------------------------
--! @file
--! @brief Custom types definition for ease of use
--! @author Gabriel de Jesus Coelho da Silva
--------------------------------------------------------------------------------

--! Use standard library with logic elements
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--! Use proposed library with fixed point definition
library ieee_proposed;
use ieee_proposed.fixed_pkg.all;

package custom_fixed_point_types is

    constant integerPart  : integer := 16;
    constant fractionalPart : integer := 16;

    subtype custom_fixed_point_type is sfixed(integerPart - 1 downto -fractionalPart);

    function to_sfixed_custom(arg : real) return unresolved_sfixed;
    function to_sfixed_custom(arg : integer) return unresolved_sfixed;
    function to_sfixed_custom(arg : std_logic_vector) return unresolved_sfixed;
end package custom_fixed_point_types;

package body custom_fixed_point_types is
    function to_sfixed_custom(arg : real) return unresolved_sfixed is
        variable result : unresolved_sfixed(integerPart - 1 downto -fractionalPart);
    begin
        result := to_sfixed(arg => arg, left_index => integerPart - 1, right_index => -fractionalPart);
        return result;
    end function to_sfixed_custom;

    function to_sfixed_custom(arg : integer) return unresolved_sfixed is
        variable result : unresolved_sfixed(integerPart - 1 downto -fractionalPart);
    begin
        result := to_sfixed(arg => arg, left_index => integerPart - 1, right_index => -fractionalPart);
        return result;
    end function to_sfixed_custom;

    function to_sfixed_custom(arg : std_logic_vector) return unresolved_sfixed is
        variable result : unresolved_sfixed(integerPart - 1 downto -fractionalPart);
    begin
        result := to_sfixed(arg => to_integer(signed(arg)), left_index => integerPart - 1, right_index => -fractionalPart);
        return result;
    end function to_sfixed_custom;

end package body custom_fixed_point_types;