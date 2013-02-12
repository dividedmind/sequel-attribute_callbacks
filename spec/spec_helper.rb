require 'sequel-attribute_callbacks'

shared_context 'database' do
  let(:dburl) { ENV['TEST_DATABASE_URL'] || 'postgres:///sequel-attribute_callbacks_test' }
  let(:db) { Sequel::connect dburl }
  
  let(:clean_database) {
    db.execute """
      DROP SCHEMA public CASCADE;
      CREATE SCHEMA public;
    """
  }
  
  before(:all) { clean_database }
end
