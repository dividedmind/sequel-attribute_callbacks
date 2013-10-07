require 'sequel-attribute_callbacks'

shared_context 'database' do
  dburl = ENV['TEST_DATABASE_URL'] || 'postgres:///sequel-attribute_callbacks_test'
  before(:all) { @db = Sequel::connect dburl }
  let(:db) { @db }
  
  def clean_database
    @db.execute """
      DROP SCHEMA public CASCADE;
      CREATE SCHEMA public;
    """
  end
  
  before(:all) { clean_database }
end
