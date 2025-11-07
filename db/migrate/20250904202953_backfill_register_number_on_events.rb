class BackfillRegisterNumberOnEvents < ActiveRecord::Migration[7.1]
  def up
    say_with_time "Populando register_number em events" do
      Event.reset_column_information

      Event.select(:weapon_id).distinct.find_each do |distinct_event|
        events = Event.where(weapon_id: distinct_event.weapon_id)
                      .order(:created_at, :id)

        events.each_with_index do |event, index|
          event.update_columns(register_number: index + 1)
        end
      end
    end

    add_index :events, [:weapon_id, :register_number], unique: true
  end

  def down
    remove_index :events, [:weapon_id, :register_number]
    remove_column :events, :register_number
  end
end
