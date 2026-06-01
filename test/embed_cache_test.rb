require "minitest/autorun"
require "tmpdir"
require_relative "../models/embed_cache"

class EmbedCacheTest < Minitest::Test
  def setup
    @dir = Dir.mktmpdir
  end

  def teardown
    require "fileutils"
    FileUtils.remove_entry(@dir)
  end

  def test_fetch_runs_block_on_miss_and_returns_value
    cache = EmbedCache.new(@dir)
    value = cache.fetch("key1") { { "title" => "hello" } }
    assert_equal({ "title" => "hello" }, value)
  end

  def test_fetch_does_not_run_block_on_hit
    EmbedCache.new(@dir).fetch("key1") { { "title" => "hello" } }

    calls = 0
    value = EmbedCache.new(@dir).fetch("key1") do
      calls += 1
      { "title" => "should not be used" }
    end

    assert_equal 0, calls, "block must not run when the key is already cached"
    assert_equal({ "title" => "hello" }, value)
  end

  def test_different_keys_are_independent
    cache = EmbedCache.new(@dir)
    a = cache.fetch("key-a") { { "v" => "a" } }
    b = cache.fetch("key-b") { { "v" => "b" } }
    assert_equal({ "v" => "a" }, a)
    assert_equal({ "v" => "b" }, b)
  end
end
