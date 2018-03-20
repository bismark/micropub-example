defmodule Micropub.Store do
  use Agent

  alias __MODULE__, as: This

  def start_link(_), do: Agent.start_link(fn -> %{posts: %{}, deleted_posts: %{}, media: %{}} end, name: This)

  def create(data) do
    Agent.get_and_update(This, fn state ->
      uid = DateTime.utc_now() |> DateTime.to_unix() |> Integer.to_string()
      {uid, put_in(state[:posts][uid], data)}
    end)
  end

  def create_media(file) do
    Agent.get_and_update(This, fn state ->
      uuid = UUID.uuid4()
      {uuid, put_in(state[:media][uuid], file)}
    end)
  end

  def update(uid, replace, add, delete) do
    Agent.update(This, fn state ->
      state = if post = state[:posts][uid] do
        props = Enum.reduce(replace, post.properties, fn {k,v}, props ->
          Map.put(props, k, v)
        end)
        props = Enum.reduce(add, props, fn {k, v}, props ->
          Map.update(props, k, v, &(&1 ++ v))
        end)
        props = Enum.reduce(delete, props, fn
          {k, v}, props ->
            if Map.has_key?(props, k) do
              Map.update!(props, k, &(&1 -- v))
            else
              props
            end
          k, props -> Map.delete(props, k)
        end)
        put_in(state[:posts][uid][:properties], props)
      else
        state
      end
      require Logger
      Logger.error inspect state
      state
    end)
  end

  def delete(uid) do
    Agent.update(This, fn state ->
      case Map.pop(state.posts, uid) do
        {nil, _} -> state
        {post, posts} ->
          deleted_posts = Map.put(state.deleted_posts, uid, post)
          %{state | posts: posts, deleted_posts: deleted_posts}
      end
    end)
  end

  def undelete(uid) do
    Agent.update(This, fn state ->
      case Map.pop(state.deleted_posts, uid) do
        {nil, _} -> state
        {post, deleted_posts} ->
          posts = Map.put(state.posts, uid, post)
          %{state | posts: posts, deleted_posts: deleted_posts}
      end
    end)
  end

  def get(uid) do
    Agent.get(This, fn state ->
      get_in(state, [:posts, uid])
    end)
  end

  def get_media(uuid) do
    Agent.get(This, fn state ->
      get_in(state, [:media, uuid])
    end)
  end
end
