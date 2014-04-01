### Rubytapas downloader

This is a small script for download all the awesome rubytapas episodes.

For those of you who doesn't know [Ruby Tapas](http://www.rubytapas.com/), it is a series of short
screencasts about ruby by [Avdi Grimm](http://devblog.avdi.org/).

You have to be subscribed in order to download the episodes. It's 9$/month, but it's worth the money.

You need to have installed ruby >= 1.9, `httparty` and `nokogiri` gems and the `curl` command.

You also need to set your email and password in the constants on the top of the script after run it.

You may also load this file via a console:

```test
$> irb -I. -r rubytapas_downloader.rb

irb(main):001:0> RubytapasDownloader.new.launch
```

This blog post may help you to understand how it works: [Rubytapas.com Downloader. How to Download Files From Https With Authentication](http://miguelcamba.com/blog/2013/05/04/rubytapas-dot-com-downloader-how-to-download-files-from-https-with-authentication/)
