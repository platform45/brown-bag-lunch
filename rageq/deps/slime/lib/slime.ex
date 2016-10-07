defmodule Slime do
  @moduledoc """
  Slim-like HTML templates.
  """

  defdelegate render(slime),           to: Slime.Renderer
  defdelegate render(slime, bindings), to: Slime.Renderer

  @doc """
  Generates a function definition from the file contents.
  The kind (`:def` or `:defp`) must be given, the
  function name, its arguments and the compilation options.
  This function is useful in case you have templates but
  you want to precompile inside a module for speed.

  ## Examples

      # sample.slim
      = a + b

      # sample.ex
      defmodule Sample do
        require Slime
        Slime.function_from_file :def, :sample, "sample.slime", [:a, :b]
      end

      # iex
      Sample.sample(1, 2) #=> "3"
  """
  defmacro function_from_file(kind, name, file, args \\ [], opts \\ []) do
    quote bind_quoted: binding do
      require EEx
      eex = file |> File.read! |> Slime.Renderer.precompile
      EEx.function_from_string(kind, name, eex, args, opts)
    end
  end

  @doc """
  Generates a function definition from the string.
  The kind (`:def` or `:defp`) must be given, the
  function name, its arguments and the compilation options.

  ## Examples

      iex> defmodule Sample do
      ...>   require Slime
      ...>   Slime.function_from_string :def, :sample, "= a + b", [:a, :b]
      ...> end
      iex> Sample.sample(1, 2)
      "3"
  """
  defmacro function_from_string(kind, name, source, args \\ [], opts \\ []) do
    quote bind_quoted: binding do
      require EEx
      eex = source |> Slime.Renderer.precompile
      EEx.function_from_string(kind, name, eex, args, opts)
    end
  end
end
