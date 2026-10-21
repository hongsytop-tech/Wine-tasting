// 앱(Dart WineSearchResult)과 공유하는 정규화된 검색 결과 형식.
export type WineType =
  | 'red'
  | 'white'
  | 'rose'
  | 'sparkling'
  | 'dessert'
  | 'fortified'
  | 'other';

export interface WineResult {
  source: string;
  sourceId: string;
  name: string;
  producer: string;
  vintage: number | null;
  type: WineType;
  country: string;
  region: string;
  grapes: string[];
  imageUrl: string;
  sourceUrl: string;
  barcode: string;
}

/** 검색 소스 1개. 새 소스(예: Wine-Searcher 유료 API, LWIN DB)는 이 형태로 추가. */
export interface WineSource {
  id: string;
  /** 키·설정이 없으면 false → 호출하지 않음. */
  enabled(): boolean;
  searchByName(q: string): Promise<WineResult[]>;
  searchByBarcode(code: string): Promise<WineResult[]>;
}
