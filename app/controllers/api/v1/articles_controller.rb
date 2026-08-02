module Api
  module V1
    class ArticlesController < BaseController
      ALLOWED_SORTS = {
        "published_at" => { published_at: :desc },
        "score" => Arel.sql("score DESC NULLS LAST, published_at DESC"),
        "comment_count" => Arel.sql("comment_count DESC NULLS LAST, published_at DESC")
      }.freeze

      before_action :authenticate_mutation!, only: %i[bookmark unbookmark dismiss undismiss]

      def index
        page, per_page = pagination_params
        scope = article_scope
        total = scope.unscope(:includes, :order, :select).count
        articles = scope.limit(per_page).offset((page - 1) * per_page)

        render json: {
          articles: articles.map { |article| ArticleSerializer.as_json(article) },
          pagination: {
            current_page: page,
            per_page: per_page,
            total_count: total,
            total_pages: (total.to_f / per_page).ceil
          }
        }
      end

      def show
        article = Article.includes(:bookmark, :read_article, :dismissed_article).find(params[:id])
        render json: ArticleSerializer.as_json(article)
      end

      def bookmark
        article = Article.find(params[:id])
        article.bookmark!
        render json: { bookmarked: article.bookmarked? }
      end

      def unbookmark
        article = Article.find(params[:id])
        article.unbookmark!
        render json: { bookmarked: article.bookmarked? }
      end

      def dismiss
        article = Article.find(params[:id])
        dismissed = article.dismiss!
        MakeDismissalPermanentJob.set(wait: 15.seconds).perform_later(dismissed.id)
        render json: { status: "dismissed", timeout: 15 }
      end

      def undismiss
        article = Article.find(params[:id])
        article.undismiss!
        render json: { status: "restored" }
      end

      private

      def article_scope
        scope = if params[:show_read] == "true"
                  Article.not_dismissed
        else
                  Article.not_read.not_dismissed
        end

        scope = scope.search(params[:q])
        scope = apply_sort(scope.includes(:bookmark, :read_article, :dismissed_article))
        scope
      end

      def apply_sort(scope)
        key = params[:sort].presence_in(ALLOWED_SORTS.keys) || "published_at"
        scope.order(ALLOWED_SORTS[key])
      end
    end
  end
end
