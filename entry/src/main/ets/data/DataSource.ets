import { Pokemon, PokemonListItem, PokemonResponse, PokeInfo, PokeInformation } from '../Model/Pokemon';
import { EvolutionData, PokemonSpecies } from '../Model/Revolution';
import { http } from '@kit.NetworkKit';
import { AbilityData, EffectEntry, PokemonData } from '../Model/AbilityEffect';
import { DamageRelations, PokemonTypeData } from '../Model/Type';

const BASE_URL: string = 'https://pokeapi.co/api/v2/pokemon?offset=0&limit=1000';

class PokemonDataSource {
  private async requestJson<T>(url: string): Promise<T> {
    const request = http.createHttp();
    try {
      const response = await request.request(url);
      if (response.responseCode < 200 || response.responseCode >= 300) {
        throw new Error(`HTTP ${response.responseCode}: ${url}`);
      }
      return JSON.parse(response.result as string) as T;
    } catch (error) {
      console.error(`Request failed for ${url}:`, error);
      throw new Error(`Request failed: ${error}`);
    } finally {
      request.destroy();
    }
  }

  async getPokemonList(): Promise<PokemonListItem[]> {
    const pokemon: PokemonListItem[] = [];
    let nextUrl: string | null = BASE_URL;
    while (nextUrl !== null) {
      const response: PokemonResponse = await this.requestJson<PokemonResponse>(nextUrl);
      pokemon.push(...response.results);
      nextUrl = response.next;
    }
    return pokemon;
  }

  async getPokemonType(id: number): Promise<string[]> {
    const response = await this.requestJson<PokeInfo>(`https://pokeapi.co/api/v2/pokemon/${id}/`);
    return response.types.map((item) => item.type?.name || 'Unknown');
  }

  async getPokemonInfo(id: number): Promise<PokeInformation> {
    return this.requestJson<PokeInformation>(`https://pokeapi.co/api/v2/pokemon/${id}/`);
  }

  async getEvolutionUrl(speciesUrl: string): Promise<string> {
    const response = await this.requestJson<PokemonSpecies>(speciesUrl);
    return response.evolution_chain.url;
  }

  async getEvolutionChain(url: string): Promise<EvolutionData> {
    return this.requestJson<EvolutionData>(url);
  }

  async getAbilityInfo(url: string): Promise<EffectEntry[]> {
    const response = await this.requestJson<AbilityData>(url);
    return response.effect_entries;
  }

  async getAbilityPokemon(url: string): Promise<PokemonData[]> {
    const response = await this.requestJson<AbilityData>(url);
    return response.pokemon;
  }

  async getAbilityDetail(url: string): Promise<AbilityData> {
    return this.requestJson<AbilityData>(url);
  }

  async getTypeDetail(url: string): Promise<DamageRelations> {
    const response = await this.requestJson<PokemonTypeData>(url);
    return response.damage_relations;
  }
}

class MyDataSource implements IDataSource {
  private listeners: DataChangeListener[] = [];
  private dataArray: Pokemon[] = [];

  public totalCount(): number {
    return this.dataArray.length;
  }

  public getData(index: number): Pokemon {
    return this.dataArray[index];
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener);
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const index = this.listeners.indexOf(listener);
    if (index >= 0) {
      this.listeners.splice(index, 1);
    }
  }

  public setData(data: Pokemon[]): void {
    this.dataArray = data;
    this.listeners.forEach((listener) => listener.onDataReloaded());
  }
}

export { BASE_URL, PokemonDataSource, MyDataSource };
