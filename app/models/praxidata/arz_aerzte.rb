module Praxidata
  class ArzAerzte < Base
    set_table_name "TarzAerzte"
    
    belongs_to :stamm, :class_name => 'AdrStamm', :foreign_key => 'inStammID'
  end
end
