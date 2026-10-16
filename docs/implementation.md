# Implementation

## Requests and models

[DataSource.ets](../entry/src/main/ets/data/DataSource.ets) uses the `@kit.NetworkKit` HTTP client. Its `requestJson` helper checks the response status, parses JSON into the requested model, and destroys the request in `finally`. `getPokemonList` follows PokéAPI's `next` links, starting with a 1,000-item page; detail methods request a Pokémon, type, ability, species, or evolution chain as needed. The response shapes are defined in [Model/](../entry/src/main/ets/Model/).

## List and type loading

[EntryAbility.ets](../entry/src/main/ets/entryability/EntryAbility.ets) loads [Index.ets](../entry/src/main/ets/pages/Index.ets). The page fetches the Pokémon list, builds each sprite URL from its ID, and passes the results to a custom `IDataSource` for `LazyForEach`. Search filters the loaded names locally.

Type labels are fetched after rows become visible. `Index.ets` delays requests during scrolling or navigation, allows one type request at a time, and batches type state updates. Failed type requests show a retry control on the affected row. This is the current solution to asynchronous row data; the earlier `Promise.all` example no longer describes this implementation.

## Detail navigation

[PokeDetail.ets](../entry/src/main/ets/pages/PokeDetail.ets) loads a selected Pokémon's measurements, types, and abilities, then separately loads its evolution chain. Its type and ability controls navigate to [TypeDetail.ets](../entry/src/main/ets/pages/TypeDetail.ets) and [AbilityDetail.ets](../entry/src/main/ets/pages/AbilityDetail.ets). The type page displays attack and defense damage relationships. The ability page selects the English effect entry and lists Pokémon with that ability. [unitFormatConverter.ets](../entry/src/main/ets/utils/unitFormatConverter.ets) extracts IDs from URLs and converts height and weight units.

## Loading and failures

The pages display loading states and offer retries after request failures. The list and detail pages share `LoadComponent` and `HttpErrorComponent` from [Index.ets](../entry/src/main/ets/pages/Index.ets). Pokémon details distinguish HTTP 429 and 404 responses in their messages. Evolution loading can fail separately from the main detail view, with its own retry control.
