require "spec_helper"
include AutomationSpecHelper

describe MiqAeDomain do
  before do
    EvmSpecHelper.local_guid_miq_server_zone
    @user = FactoryGirl.create(:user_with_group)
    @temp_dir = Dir.mktmpdir
    require 'miq_ae_datastore'
    stub_const("MiqAeDatastore::DATASTORE_DIRECTORY", @temp_dir)
  end

  after do
    FileUtils.remove_entry_secure(@temp_dir) if Dir.exist?(@temp_dir)
  end

  context "version" do
    it "no about class" do
      d1 = FactoryGirl.create(:miq_ae_domain, :name => 'Obelix')
      expect(d1.version).to be_nil
    end

    it "about class present" do
      ver = '3.0.9'
      expect(create_about_class('Dogmatix', ver).version).to eq(ver)
    end
  end

  context "available_version" do
    it "no version specified" do
      d1 = FactoryGirl.create(:miq_ae_domain, :name => 'Asterix')
      expect(d1.available_version).to be_nil
    end

    it "about file present" do
      version = '7.1.1'
      dom2 = create_about_class('Vitalstatistix', version)
      write_about_file(dom2)
      expect(dom2.available_version).to eq('7.1.1')
    end
  end

  def write_about_file(domain)
    obj = MiqAeClass.find_by_fqname("/#{domain.name}/System/About")
    hash = {'object_type' => CLASS_OBJ_TYPE,
            'version'     => VERSION,
            'object'      => {'attributes' => obj.export_attributes,
                              'schema'     => obj.export_schema}}
    fname = File.join(MiqAeDatastore::DATASTORE_DIRECTORY, domain.name.downcase, 'system',
                      "about#{CLASS_DIR_SUFFIX}", CLASS_YAML_FILENAME)
    dirname = File.dirname(fname)
    FileUtils.mkdir_p(dirname) unless File.directory?(dirname)
    File.write(fname, hash.to_yaml)
  end

  def create_about_class(domain, version)
    ae_fields = {'version' => {:aetype => 'attribute', :datatype => 'string', :default_value => version},
                 'tree'    => {:aetype => 'attribute', :datatype => 'string', :default_value => "ast"}}
    ae_instances = {'instance1' => {'version' => {:value => 'hello world'},
                                    'tree'    => {:value => 'adt'}}}
    create_ae_model(:name         => domain,
                    :ae_class     => 'About',
                    :ae_namespace => 'System',
                    :ae_fields    => ae_fields,
                    :ae_instances => ae_instances)
  end
end
