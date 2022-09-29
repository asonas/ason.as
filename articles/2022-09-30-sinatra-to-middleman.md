---
date:  2022-09-30 00:00:00
title: sinatra2middleman
---
このブログをつくったのが2020年の10月なんだけど、いろいろな思いがあって自前のブログシステムを作った。

sinatraで動かして動的にHTMLを返すみたいな仕組みだった。インフラ面はすべてHerokuにお任せする感じだった。昨今の円安とかもあって、Herokuにかかるお金が桁がひとつ変わってきたというのもあってHerokuじゃなくてもよいやつは自宅のサーバーから動かすようにした。

<blockquote class="twitter-tweet"><p lang="ja" dir="ltr">仕事の合間の癒やしとして、Herokuから自宅サーバーやAWS（主にS3）に移行するというのをやっていて残すところ <a href="https://t.co/MYRPgesAoN">https://t.co/MYRPgesAoN</a> だけになった...。</p>&mdash; あそなす (@asonas) <a href="https://twitter.com/asonas/status/1566465445838090240?ref_src=twsrc%5Etfw">September 4, 2022</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

9月の頭ぐらいから始めて最後に残っていたこのブログだけがずっと残っていた。RubyKaigi中にでも片付けてしまおうかと思ったけどトークに集中していたら一瞬で過ぎ去っていった。

脱Herokuをする上でSinatraではなく静的なHTMLを生成してS3に置くようにした。SSL証明書がほしかったり画像あたりを高速に配信できるようにしたかったのでCloudFrontをおいた。ふつうのS3とCloudFrontを利用した静的サイトの構成になっている。

工夫した点としては、

1. deployのタイミングで更新したファイルのキャッシュを破棄するようにした。
2. AWSのアクセスはOpenID経由でアクセスするようにした。

あたりだろうか。1.については新しいファイルについては問題ないけど、テキストや画像を更新したときにキャッシュを破棄して新鮮なコンテンツをお届けできるようにしたかったから。https://ason.as/revision というURLにデプロイされているgitのコミットハッシュを書いておいてデプロイ時にその時との差分をみて更新されたファイルがあればそのファイルのキャッシュを破棄する、という感じ。 `*` で全部破棄すれば良いんだけどせっかくなので必要なファイルだけのキャッシュを飛ばす。あと、キャッシュの破棄にもお金がかかるので必要なファイルだけにしておくのがお安く済む。

https://docs.aws.amazon.com/ja_jp/AmazonCloudFront/latest/DeveloperGuide/Invalidation.html

2.については最近社内でも利用しているGitHub Actions経由でAWSのロールをAssumeしているのをおさらいしたかったから。これもドキュメントに書いてあるのをそのまま実践しただけなのであんまり面白みとかはない。

https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services

そんな感じで移行した。あと、この仕組みはRubyである必要もないのでRustの勉強がてら書き直してみようかなと思う。
