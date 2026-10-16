import { PokemonDataSource, MyDataSource } from '../data/DataSource';
import { Pokemon } from '../Model/Pokemon';
import { extractLastNumber } from '../utils/unitFormatConverter';

@Entry
@Component
struct Index {
  @State isLoading: boolean = false;
  @State errorMessage: string = '';
  @State pokeList: Pokemon[] = [];
  @State typeList: string[][] = [];
  @State changeValue: string = '';
  @State filteredPokemon: Pokemon[] = [];
  private scroller: Scroller = new Scroller();
  private dataSet: MyDataSource = new MyDataSource();
  private searchController: SearchController = new SearchController();
  private typeSource: PokemonDataSource = new PokemonDataSource();
  private requestedTypeIds: Set<number> = new Set<number>();
  private visibleTypeIds: Set<number> = new Set<number>();
  private failedTypeIds: Set<number> = new Set<number>();
  private pendingTypes: Map<number, string[]> = new Map<number, string[]>();
  private activeTypeRequests: number = 0;
  private typeLoadGeneration: number = 0;
  private isScrolling: boolean = false;
  private isOpeningPokemon: boolean = false;
  private firstVisibleIndex: number = 0;
  private lastVisibleIndex: number = -1;
  private typeLoadTimer: number = -1;
  private typeUpdateTimer: number = -1;

  aboutToAppear(): void {
    this.loadPokemon();
  }

  onPageShow(): void {
    this.isOpeningPokemon = false;
    this.isScrolling = false;
    this.scheduleTypeUpdate();
    this.scheduleTypes();
  }

  aboutToDisappear(): void {
    this.isOpeningPokemon = true;
    this.clearTypeTimers();
  }

  private clearTypeTimers(): void {
    if (this.typeLoadTimer >= 0) {
      clearTimeout(this.typeLoadTimer);
      this.typeLoadTimer = -1;
    }
    if (this.typeUpdateTimer >= 0) {
      clearTimeout(this.typeUpdateTimer);
      this.typeUpdateTimer = -1;
    }
  }

  private async loadPokemon(): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';
    this.typeLoadGeneration += 1;
    this.clearTypeTimers();
    this.typeList = [];
    this.requestedTypeIds.clear();
    this.visibleTypeIds.clear();
    this.failedTypeIds.clear();
    this.pendingTypes.clear();
    this.activeTypeRequests = 0;
    this.isScrolling = false;
    this.isOpeningPokemon = false;
    this.lastVisibleIndex = -1;
    try {
      const source = new PokemonDataSource();
      const results = await source.getPokemonList();
      const list: Pokemon[] = results.map((item) => {
        const id = extractLastNumber(item.url);
        const pokemon: Pokemon = {
          name: item.name,
          url: item.url,
          image: `https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${id}.png`
        };
        return pokemon;
      });
      this.pokeList = list;
      this.updateFilter();
    } catch (error) {
      console.error('Failed to load Pokémon list:', error);
      this.errorMessage = 'Could not load Pokémon. Check your connection and try again.';
    } finally {
      this.isLoading = false;
    }
  }

  private appearType(item: Pokemon): void {
    const id = extractLastNumber(item.url);
    this.visibleTypeIds.delete(id);
    this.visibleTypeIds.add(id);
    this.scheduleTypes();
  }

  private leaveType(item: Pokemon): void {
    const id = extractLastNumber(item.url);
    this.visibleTypeIds.delete(id);
  }

  private retryType(item: Pokemon): void {
    const id = extractLastNumber(item.url);
    this.failedTypeIds.delete(id);
    this.scheduleTypes();
  }

  private scheduleTypes(): void {
    if (this.isScrolling || this.isOpeningPokemon) {
      return;
    }
    if (this.typeLoadTimer >= 0) {
      clearTimeout(this.typeLoadTimer);
    }
    this.typeLoadTimer = setTimeout(() => {
      this.typeLoadTimer = -1;
      this.pumpTypes();
    }, 180);
  }

  private pumpTypes(): void {
    if (this.isScrolling || this.isOpeningPokemon || this.activeTypeRequests > 0) {
      return;
    }
    let nextId: number = 0;
    if (this.lastVisibleIndex >= 0) {
      for (let index = this.firstVisibleIndex; index <= this.lastVisibleIndex; index++) {
        const item = this.dataSet.getData(index);
        if (item) {
          const id = extractLastNumber(item.url);
          if (!this.requestedTypeIds.has(id) && !this.failedTypeIds.has(id)) {
            nextId = id;
          }
        }
      }
    } else {
      this.visibleTypeIds.forEach((id) => {
        if (!this.requestedTypeIds.has(id) && !this.failedTypeIds.has(id)) {
          nextId = id;
        }
      });
    }
    if (nextId > 0) {
      this.requestedTypeIds.add(nextId);
      this.activeTypeRequests = 1;
      this.loadType(nextId, this.typeLoadGeneration);
    }
  }

  private scheduleTypeUpdate(): void {
    if (this.isScrolling || this.isOpeningPokemon || this.typeUpdateTimer >= 0) {
      return;
    }
    this.typeUpdateTimer = setTimeout(() => {
      this.typeUpdateTimer = -1;
      if (this.isScrolling || this.isOpeningPokemon || this.pendingTypes.size === 0) {
        return;
      }
      const nextTypes = this.typeList.slice();
      this.pendingTypes.forEach((types, id) => {
        nextTypes[id] = types;
      });
      this.pendingTypes.clear();
      this.typeList = nextTypes;
    }, 120);
  }

  private async loadType(id: number, generation: number): Promise<void> {
    try {
      const types = await this.typeSource.getPokemonType(id);
      if (generation === this.typeLoadGeneration) {
        this.pendingTypes.set(id, types);
        this.scheduleTypeUpdate();
      }
    } catch (error) {
      console.warn(`Could not load types for Pokémon ${id}: ${error}`);
      if (generation === this.typeLoadGeneration) {
        this.pendingTypes.set(id, []);
        this.failedTypeIds.add(id);
        this.requestedTypeIds.delete(id);
        this.scheduleTypeUpdate();
      }
    } finally {
      if (generation === this.typeLoadGeneration) {
        this.activeTypeRequests = 0;
        this.pumpTypes();
      }
    }
  }

  private updateFilter(): void {
    const query = this.changeValue.trim().toLowerCase();
    this.lastVisibleIndex = -1;
    this.filteredPokemon = query.length === 0 ? [] : this.pokeList.filter((pokemon) => {
      return pokemon.name.toLowerCase().includes(query);
    });
    this.dataSet.setData(query.length === 0 ? this.pokeList : this.filteredPokemon);
  }

  private openPokemon(item: Pokemon): void {
    const id = extractLastNumber(item.url);
    this.isOpeningPokemon = true;
    this.clearTypeTimers();
    try {
      this.getUIContext().getRouter().pushUrl({
        url: 'pages/PokeDetail',
        params: { pokeName: item.name, pokeId: id, pokeImage: item.image }
      });
    } catch (error) {
      this.isOpeningPokemon = false;
      this.scheduleTypeUpdate();
      this.scheduleTypes();
      console.error('Could not open Pokémon details:', error);
    }
  }

  @Builder
  PokemonRow(item: Pokemon) {
    Row({ space: 12 }) {
      Row({ space: 12 }) {
        Image(item.image)
          .width(60)
          .height(60)
          .backgroundColor('#F8F3FF')
          .borderRadius(14);
        Column({ space: 4 }) {
          Text(item.name)
            .fontSize(18)
            .fontWeight(700)
            .fontColor('#0F0026')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis });
          Text(this.typeList[extractLastNumber(item.url)] === undefined ? 'Types loading' :
            this.typeList[extractLastNumber(item.url)].join(' · ') || 'Types unavailable')
            .fontSize(13)
            .fontColor('#6024B5')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis });
        }
        .layoutWeight(1);
        Text(`#${extractLastNumber(item.url)}`)
          .fontSize(13)
          .fontWeight(600)
          .fontColor('#5E5470');
      }
      .layoutWeight(1)
      .onClick(() => this.openPokemon(item));
      if (this.typeList[extractLastNumber(item.url)] !== undefined &&
        this.typeList[extractLastNumber(item.url)].length === 0) {
        Button('Retry')
          .fontSize(12)
          .height(26)
          .backgroundColor('#6024B5')
          .onClick(() => this.retryType(item));
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(18)
    .margin({ bottom: 10 });
  }

  build() {
    Column({ space: 16 }) {
      Row() {
        Text('Pokémon')
          .fontSize(30)
          .fontWeight(800)
          .fontColor('#0F0026');
      }
      .width('100%')
      .margin({ top: 10 });

      Search({ value: this.changeValue, placeholder: 'Search Pokémon', controller: this.searchController })
        .width('100%')
        .height(50)
        .backgroundColor('#FFFFFF')
        .borderRadius(14)
        .onChange((value: string) => {
          this.changeValue = value;
          this.updateFilter();
        });

      if (this.isLoading) {
        LoadComponent();
      } else if (this.errorMessage.length > 0) {
        HttpErrorComponent({ text: this.errorMessage });
        Button('Retry')
          .backgroundColor('#6024B5')
          .onClick(() => this.loadPokemon());
      } else if (this.pokeList.length === 0) {
        this.EmptyState('No Pokémon are available.');
      } else if (this.changeValue.trim().length > 0 && this.filteredPokemon.length === 0) {
        this.EmptyState('No Pokémon match your search.');
      } else {
        List({ scroller: this.scroller }) {
          LazyForEach(this.dataSet, (item: Pokemon) => {
            ListItem() {
              this.PokemonRow(item);
            }
            .onAppear(() => this.appearType(item))
            .onDisAppear(() => this.leaveType(item));
          }, (item: Pokemon) => item.url);
        }
        .cachedCount(4)
        .onScrollStart(() => {
          this.isScrolling = true;
          this.clearTypeTimers();
        })
        .onScrollIndex((start: number, end: number) => {
          this.firstVisibleIndex = start;
          this.lastVisibleIndex = end;
          this.scheduleTypes();
        })
        .onScrollStop(() => {
          this.isScrolling = false;
          this.scheduleTypeUpdate();
          this.scheduleTypes();
        })
        .layoutWeight(1);
      }
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16 })
    .backgroundColor('#F8F3FF');
  }

  @Builder
  EmptyState(message: string) {
    Column({ space: 10 }) {
      Text(message)
        .fontSize(17)
        .fontColor('#0F0026')
        .textAlign(TextAlign.Center);
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center);
  }
}

@Component
export struct LoadComponent {
  @Prop label: string = 'Loading Pokémon…';

  build() {
    Column({ space: 14 }) {
      LoadingProgress().color('#6024B5').width(48).height(48);
      Text(this.label)
        .fontSize(16)
        .fontColor('#5E5470');
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center);
  }
}

@Component
export struct HttpErrorComponent {
  @Prop text: string = '';

  build() {
    Column({ space: 12 }) {
      Image($r('app.media.ic_no_wifi'))
        .width(56)
        .height(56)
        .opacity(0.7);
      Text(this.text)
        .fontSize(16)
        .fontColor('#0F0026')
        .textAlign(TextAlign.Center);
    }
    .width('100%')
    .padding({ left: 24, right: 24 })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center);
  }
}
