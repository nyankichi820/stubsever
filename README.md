# API Stub Server
クライアント開発に置いてAPI連携部分の実装を楽にするためのスタブサーバーです。

* responseをローカルのjson fileを指定して返せる
* stubしない物はproxyサーバーになり、別サーバー（例えば本番サーバー）へリクエストを飛ばします。
* proxyリクエストは自動的にjson fileにおちるので、そのままテストデータに使えます。
* APIの仕様管理を簡易的に行えます。

## Install

stub server のみ
```
cd stub
bundle install
```

stub 管理 web serverも使う場合はgrunt,sass,bowerなどが必要になります。

```
npm install 
grunt 
```


## Usage

### run server 

```
bundle exec rackup -p 3000
```

### setup stub reqsponse 

config/fixture.ymlにstubしたいリクエストの設定を書くことでjsonを返すことができます。

*例: http://xxxx/topにリクエストが来たらstub/fixtures/top.jsonをかえす*

```
  - route: /stub/sample
    route_sample: /stub/sample
    description : stubサンプル
    file : sample
```

またさらに別サーバーへのリクエストをプロキシすることも可能です。

*例: http://xxxx/topにリクエストが来たらhttp://zzzzzzz/topの内容ををかえす*

```
  - route: /stub/sample
    route_sample: /stub/sample
    description : stubサンプル
    url  : http://zzzzzzz/top
```


返すJSONはjson5対応してあるためコメント、keyに対する"の省略などが可能です

```
{
  // comment かける！
  response: {
    // quote いらない！！
    title : "タイトル",
    // 下記のような記述で定義からサンプルデータを読み込めます
    lists : <%%= fixture("lists_sample") %>
  }, // ケツカンマおっけ
}
```

### describe definition
APIの仕様を簡易的に管理するための機能を持ち合わせています。
管理用のWeb Serverから記述した内容を確認することができます。
カテゴリごとに記述が可能です

```
definitions:
  - description: API Common
    fixtures:
      - route: /stub/common/response
        route_sample: /stub/common/response
        description : API共通フォーマット
        file : entity/user
  - description: Entities
    fixtures:
      - route: /stub/entity/user
        route_sample: /stub/entity/user
        description : Userエンティティ
        file : entity/user
```

さらにこの定義をfixture側からincludeする形で呼び出すことが
できるため、メンテナンスもしやすいです。


#### request recording
stubしないリクエストは直接ORIGIN_URLに指定したサーバーへリクエストを送り
/tmp/stub_record/以下にresponseを保存します。
これらのファイルをcopyして再利用することにより,stubデータに使用できます。


