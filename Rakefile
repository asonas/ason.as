namespace :blog do
  desc 'Create new article '
  task :create, [:subtitle] do |task, args|
    t = Time.now
    filename = "articles/#{t.strftime('%Y-%m-%d')}-#{args.subtitle}.md"

    File.open(filename, 'wb') do |f|
      f.write <<~EOS
      ---
      date:  #{t.strftime('%Y-%m-%d')} 00:00:00
      title:
      ---
    EOS
    end
  end
end
