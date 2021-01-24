--------------------------------------------------------------------------------
-- Pipelined point - nicely arranged types for easy re-use.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use work.custom_fixed_point_types.all;

package pipeline_types is
    constant depth  : integer := 3;
    subtype input_coord is std_logic_vector(integerPart + fractionalPart - 1 downto 0);
    type coord_array_type is array (integer range <>) of input_coord;
end package pipeline_types;
