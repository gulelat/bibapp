class EnrichCitationMetadata < ActiveRecord::Migration
  def self.up    
    # Create Publication Date
    add_column :citations, :publication_date, :date    

    # Add Language & Copyright Holder
    add_column :citations, :language, :string
    add_column :citations, :copyright_holder, :string
    
    #Copy Year into Publication Date
    Citation.reset_column_information
    say_with_time "Updating citations" do
      citations = Citation.find(:all)
      citations.each do |c|
        c.update_attribute(:publication_date, Date.new(c.year.to_i))
        say "Citation #{c.id} updated!", true
      end
    end

    #remove old Year column
    remove_column :citations, :year
  end

  def self.down
    remove_column :citations, :language
    remove_column :citations, :copyright_holder
    
    add_column :citations, :year, :string
    #Copy Publication Date back to Year
    Citation.reset_column_information
    say_with_time "Updating citations" do
      citations = Citation.find(:all)
      citations.each do |c|
        c.update_attribute(:year, c.publication_date.year.to_s)
        say "Citation #{c.id} updated!", true
      end
    end
    
    remove_column :citations, :publication_date
  end
end
