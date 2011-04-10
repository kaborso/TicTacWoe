module GamesHelper
  def mark_name(mark)
    case mark
      when -1 then "Skull"
      when 1 then "Heart"
     end
  end
end
