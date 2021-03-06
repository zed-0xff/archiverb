require File.expand_path("../spec_helper.rb", __FILE__)

require 'archiverb/tar'

describe Archiverb::Tar do
  include Archiverb::Test
  it "should correctly unarchive text data" do
    tar = nil
    tar = Archiverb::Tar.new(::File.join(data_dir, 'txt.gnu.tar')).read
    tar.files.size.should == 3
    tar["data/heneryIV.txt"].should_not be_nil
    tar["data/heneryIV.txt"].should untar_as("heneryIV.txt")
    tar["data/heneryIV-westmoreland.txt"].should_not be_nil
    tar["data/heneryIV-westmoreland.txt"].should untar_as("heneryIV-westmoreland.txt")
    tar["data/henryIV.txt"].should_not be_nil
    tar["data/henryIV.txt"].stat.ftype.should == "link"
    tar["data/henryIV.txt"].stat.readlink.should == "heneryIV.txt"
  end # should correctly unarchive text data

  it "should correctly unarchive text data with limit" do
    tar = Archiverb::Tar.new(::File.join(data_dir, 'txt.gnu.tar')).read(:limit => 1)
    tar.files.size.should == 1
    tar["data/heneryIV.txt"].should_not be_nil
    tar["data/heneryIV.txt"].should untar_as("heneryIV.txt")
  end

  it "should unarchive only files selected by glob" do
    tar = Archiverb::Tar.new(::File.join(data_dir, 'txt.gnu.tar')).read(:filter => "data/henery*")
    tar.files.size.should == 2
    tar["data/heneryIV.txt"].should_not be_nil
    tar["data/heneryIV.txt"].should untar_as("heneryIV.txt")
    tar["data/heneryIV-westmoreland.txt"].should_not be_nil
    tar["data/heneryIV-westmoreland.txt"].should untar_as("heneryIV-westmoreland.txt")

    tar = Archiverb::Tar.new(::File.join(data_dir, 'txt.gnu.tar')).read(:filter => "*westmore*")
    tar.files.size.should == 1
    tar["data/heneryIV-westmoreland.txt"].should_not be_nil
    tar["data/heneryIV-westmoreland.txt"].should untar_as("heneryIV-westmoreland.txt")
  end

  it "should unarchive only files selected by glob with limit" do
    tar = Archiverb::Tar.new(::File.join(data_dir, 'txt.gnu.tar')).read(:filter => "data/henery*", :limit => 1)
    tar.files.size.should == 1
    tar["data/heneryIV.txt"].should_not be_nil
    tar["data/heneryIV.txt"].should untar_as("heneryIV.txt")
  end

  it "should unarchive only files selected by regexp" do
    tar = Archiverb::Tar.new(::File.join(data_dir, 'txt.gnu.tar')).read(:filter => %r|data/henery.*|)
    tar.files.size.should == 2
    tar["data/heneryIV.txt"].should_not be_nil
    tar["data/heneryIV.txt"].should untar_as("heneryIV.txt")
    tar["data/heneryIV-westmoreland.txt"].should_not be_nil
    tar["data/heneryIV-westmoreland.txt"].should untar_as("heneryIV-westmoreland.txt")

    tar = Archiverb::Tar.new(::File.join(data_dir, 'txt.gnu.tar')).read(:filter => /westmore/)
    tar.files.size.should == 1
    tar["data/heneryIV-westmoreland.txt"].should_not be_nil
    tar["data/heneryIV-westmoreland.txt"].should untar_as("heneryIV-westmoreland.txt")
  end

  it "should unarchive only files selected by regexp with limit" do
    tar = Archiverb::Tar.new(::File.join(data_dir, 'txt.gnu.tar')).read(:filter => %r|data/henery.*|, :limit => 1)
    tar.files.size.should == 1
    tar["data/heneryIV.txt"].should_not be_nil
    tar["data/heneryIV.txt"].should untar_as("heneryIV.txt")
  end

  it "should raise error on unsupported filter" do
    filter = 123
    lambda {
      Archiverb::Tar.new(::File.join(data_dir, 'txt.gnu.tar')).read(:filter => filter)
    }.should raise_error(ArgumentError, "unsupported filter type: #{filter.class}")
  end

  it "should correctly tar text data" do
    Dir.chdir(File.join(File.dirname(__FILE__), "data")) do
      Archiverb::Tar.new.tap do |archive|
        stat = { :mtime => 1360125720, :mode => 0755, :uid => 1000, :gid => 1000 }
        archive.add("heneryIV-westmoreland.txt", stat)
        archive.add("heneryIV.txt", stat)
        archive.files.each{ |f| f.stat.uname = "user"; f.stat.gname = "group" }
        archive.count.should == 2
        archive.files.should_not be_empty
        archive.names == ['heneryIV-westmoreland.txt', 'heneryIV.txt']
        archive.write do |raw|
          Digest::MD5.hexdigest(raw).should == "9e8f96d0fe578cf5549c82adc881be8e"
        end # raw
      end # archive
    end
  end # should correctly tar text data

  it "should correctly tar text data and directory" do
    Dir.chdir(File.dirname(__FILE__)) do
      Archiverb::Tar.new.tap do |archive|
        stat = { :mtime => 1360125720, :mode => 0755, :uid => 1000, :gid => 1000 }
        archive.add("data/", stat)
        archive.add("data/heneryIV-westmoreland.txt", stat)
        archive.add("data/heneryIV.txt", stat)
        archive.files.each{ |f| f.stat.uname = "user"; f.stat.gname = "group" }
        archive.count.should == 3
        archive.files.should_not be_empty
        archive.names == ['data/heneryIV-westmoreland.txt', 'data/heneryIV.txt']
        archive.write do |raw|
          Digest::MD5.hexdigest(raw).should == "eaf37cfe9b5f0b7b4c8dbf236ce6bd7e"
        end # raw
      end # archive
    end
  end # should correctly tar text data and directory

  it "should add non-existent directories" do
    Dir.chdir(File.dirname(__FILE__)) do
      Archiverb::Tar.new.tap do |archive|
        stat = { :mtime => 1360125720, :mode => 0755, :uid => 1000, :gid => 1000 }
        archive.add("tmp_dir/", stat)
        archive.add("tmp_dir/heneryIV-westmoreland.txt",
                    File.new("data/heneryIV-westmoreland.txt"),
                    stat)
        archive.add("tmp_dir/heneryIV.txt",
                    File.new("data/heneryIV.txt"),
                    stat)
        archive.files.each{ |f| f.stat.uname = "user"; f.stat.gname = "group" }
        archive.count.should == 3
        archive.files.should_not be_empty
        archive.names == ['data/heneryIV-westmoreland.txt', 'data/heneryIV.txt']
        archive.write do |raw|
          Digest::MD5.hexdigest(raw).should == "9d43f14bf9bc342124e42c4f81ceade5"
        end # raw
      end # archive
    end
  end

  it "should correctly tar links"
end # Archiverb::Tar
