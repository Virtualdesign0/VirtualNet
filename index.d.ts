declare namespace VNet {
	export type Lane = "reliable" | "fast";
	export type Disconnect = (this: void) => void;
	export type PayloadArgs<T> = T extends void ? [] : [payload: T];
	export type BatchPayload<T> = T extends void ? undefined : T;
	export type BatchPayloads<T> = Array<BatchPayload<T>>;
	export type Peer = "client" | "server" | "shared";
	export type RejectReason = unknown;
	export type PromiseResult<T> = unknown;
	export type Variant<K extends string = string, V = unknown> = {
		kind: K;
		value: V;
	};

	export const TypeGuardBrand: unique symbol;
	export const PacketBrand: unique symbol;
	export const RequestBrand: unique symbol;
	export const GroupBrand: unique symbol;
	export const DeltaBrand: unique symbol;

	export interface TypeGuard<T = unknown> {
		readonly kind: string;
		readonly [TypeGuardBrand]: T;
	}

	export type U4Payload = [number, number];
	export type Boolean1Payload = [
		boolean,
		boolean,
		boolean,
		boolean,
		boolean,
		boolean,
		boolean,
		boolean,
	];

	export type ScalarName =
		| "any"
		| "unknown"
		| "bool"
		| "boolean"
		| "Boolean8"
		| "boolean8"
		| "Boolean1"
		| "boolean1"
		| "string"
		| "str"
		| "none"
		| "nil"
		| "nil_"
		| "U4"
		| "u4"
		| "U8"
		| "u8"
		| "uint8"
		| "U16"
		| "u16"
		| "uint16"
		| "U24"
		| "u24"
		| "uint24"
		| "U32"
		| "u32"
		| "uint32"
		| "playerId"
		| "playerid"
		| "PlayerId"
		| "entityId"
		| "entityid"
		| "EntityId"
		| "S8"
		| "s8"
		| "i8"
		| "int8"
		| "S16"
		| "s16"
		| "i16"
		| "int16"
		| "S24"
		| "s24"
		| "i24"
		| "int24"
		| "S32"
		| "s32"
		| "i32"
		| "int32"
		| "F16"
		| "f16"
		| "float16"
		| "F24"
		| "f24"
		| "float24"
		| "F32"
		| "f32"
		| "float32"
		| "float"
		| "F64"
		| "f64"
		| "float64"
		| "double"
		| "number"
		| "Vector2"
		| "vec2"
		| "vector2"
		| "Vector2S16"
		| "vector2s16"
		| "Vector2F24"
		| "vector2f24"
		| "Vector2F32"
		| "vector2f32"
		| "Vector3"
		| "vec3"
		| "vector3"
		| "Vector3S16"
		| "vector3s16"
		| "Vector3F24"
		| "vector3f24"
		| "Vector3F32"
		| "vector3f32"
		| "qvec3_i16"
		| "qnormal_i16"
		| "qyaw_u8"
		| "qangle_u16"
		| "qalpha_u8"
		| "qtransform_yaw_i16"
		| "CFrame"
		| "CFrameF24U8"
		| "cframef24u8"
		| "cframe"
		| "NumberRange"
		| "numberrange"
		| "NumberSequence"
		| "numbersequence"
		| "Color3"
		| "color3"
		| "ColorSequence"
		| "colorsequence"
		| "Region3"
		| "region3"
		| "Rect"
		| "rect"
		| "BrickColor"
		| "brickcolor"
		| "UDim"
		| "udim"
		| "UDim2"
		| "udim2"
		| "player"
		| "character"
		| "buffer"
		| "buff";

	export type ScalarPayloadByKind<T> = T extends "any"
		? any
		: T extends "unknown"
			? unknown
			: T extends "boolean1"
				? Boolean1Payload
				: T extends "bool" | "boolean" | "boolean8"
				? boolean
					: T extends "string" | "str"
						? string
						: T extends "none" | "nil" | "nil_"
							? void
							: T extends "u4"
								? U4Payload
								: T extends
											| "u8"
											| "uint8"
											| "u16"
											| "uint16"
											| "u24"
											| "uint24"
											| "u32"
											| "uint32"
											| "s8"
											| "i8"
											| "int8"
											| "s16"
											| "i16"
											| "int16"
											| "s24"
											| "i24"
											| "int24"
											| "s32"
											| "i32"
											| "int32"
											| "f16"
											| "float16"
											| "f24"
											| "float24"
											| "f32"
											| "float32"
											| "float"
											| "f64"
											| "float64"
											| "double"
											| "number"
											| "playerid"
											| "entityid"
											| "qyaw_u8"
											| "qangle_u16"
											| "qalpha_u8"
									? number
									: T extends "vec2" | "vector2" | "vector2s16" | "vector2f24" | "vector2f32"
										? Vector2
										: T extends "vec3" | "vector3" | "vector3s16" | "vector3f24" | "vector3f32" | "qvec3_i16" | "qnormal_i16"
											? Vector3
											: T extends "qtransform_yaw_i16" | "cframe" | "cframef24u8"
												? CFrame
												: T extends "numberrange"
													? NumberRange
													: T extends "numbersequence"
														? NumberSequence
														: T extends "color3"
															? Color3
															: T extends "colorsequence"
																? ColorSequence
																: T extends "region3"
																	? Region3
																	: T extends "rect"
																		? Rect
																		: T extends "brickcolor"
																			? BrickColor
																			: T extends "udim"
																				? UDim
																				: T extends "udim2"
																					? UDim2
																					: T extends "player"
																						? Player
																						: T extends "character"
																							? Model
																							: T extends "buffer" | "buff"
																								? buffer
																								: never;

	export type ScalarPayload<T> = T extends string ? ScalarPayloadByKind<Lowercase<T>> : never;

	export type SchemaValue = ScalarName | TypeGuard<any> | ObjectSchema;
	export type ObjectSchema = {
		readonly [field: string]: SchemaValue;
	};

	export type SchemaNode =
		| SchemaValue
		| PacketDefinition<any>
		| DeltaDefinition<any, any>
		| RequestDefinition<any, any>
		| GroupDefinition<any>;

	export interface NetworkSchema {
		readonly [packetName: string]: SchemaNode;
	}

	export type Infer<T> = T extends TypeGuard<infer Payload>
		? Payload
		: T extends ScalarName
			? ScalarPayload<T>
			: T extends ObjectSchema
				? { [K in keyof T]: Infer<T[K]> }
				: unknown;

	export type InferMapKey<T> = Infer<T> extends infer Key ? Extract<Key, string | number> : never;
	export type MapPayload<K extends string | number, V> = K extends string ? Record<string, V> : Record<number, V>;
	export type InferTuple<T extends readonly SchemaValue[]> = {
		[K in keyof T]: Infer<T[K]>;
	};
	export type InferVariantCases<T extends Record<string, SchemaValue>> = {
		[K in keyof T & string]: Variant<K, Infer<T[K]>>;
	}[keyof T & string];
	export type DeltaShape<T extends ObjectSchema> = {
		readonly [K in keyof T]: Infer<T[K]>;
	};
	export type DeltaPatch<T extends ObjectSchema> = Partial<DeltaShape<T>>;
	export type DeltaPayload<Id, T extends ObjectSchema> = {
		id: Id;
		changes: DeltaPatch<T>;
	};
	export type PacketPolicyValidator<T = unknown> = (
		this: void,
		player: Player | undefined,
		payload: T,
	) => boolean;

	export interface PacketPolicy<T = unknown> {
		rate?: number | string;
		burst?: number;
		validate?: PacketPolicyValidator<T>;
		validator?: PacketPolicyValidator<T>;
		onViolation?: "drop" | "warn" | "kick" | "error" | string;
	}

	export interface PacketOptions {
		id?: number;
		name?: string;
		lane?: Lane;
		fast?: boolean;
		reliable?: boolean;
		immediate?: boolean;
		direct?: boolean;
		defer?: boolean;
		queueEarly?: boolean;
		validate?: boolean | PacketPolicyValidator<any>;
		rate?: number | string;
		burst?: number;
		policy?: PacketPolicy<any>;
		validator?: PacketPolicyValidator<any>;
		onViolation?: "drop" | "warn" | "kick" | "error" | string;
	}

	export interface AuditOptions {
		audit?: boolean;
		requireExplicitIds?: boolean;
		allowUnpacked?: boolean;
	}

	export interface BuildOptions extends AuditOptions {}
	export interface DirectPacketOptions extends PacketOptions, AuditOptions {}
	export interface PacketConfigOptions extends PacketOptions {}
	export interface DeltaOptions<Id extends SchemaValue = "u32"> extends PacketConfigOptions {
		entityId?: Id;
		entityIdSpec?: Id;
		idSpec?: Id;
	}
	export interface TransactionOptions<T = unknown> extends PacketConfigOptions {
		transactionKey?: string;
		idempotencyKey?: string;
		transactionTtl?: number;
		transactionTtlSeconds?: number;
		transactionMaxKeys?: number;
		transactionCapacity?: number;
		policy?: PacketPolicy<T>;
	}

	export interface PacketDefinition<T> {
		readonly [PacketBrand]: T;
	}

	export interface DeltaDefinition<Id, Shape extends ObjectSchema> {
		readonly [DeltaBrand]: {
			id: Id;
			shape: Shape;
		};
	}

	export interface RequestDefinition<Input, Output> {
		readonly [RequestBrand]: {
			input: Input;
			output: Output;
		};
	}

	export interface GroupDefinition<T extends NetworkSchema> {
		readonly [GroupBrand]: T;
	}

	export type PacketPayload<T> = T extends PacketDefinition<infer Payload> ? Payload : Infer<T>;
	export type DeltaEntityId<T> = T extends DeltaDefinition<infer Id, any> ? Id : never;
	export type DeltaSchema<T> = T extends DeltaDefinition<any, infer Shape> ? Shape : never;
	export type RequestInput<T> = T extends RequestDefinition<infer Input, any> ? Input : never;
	export type RequestOutput<T> = T extends RequestDefinition<any, infer Output> ? Output : never;
	export type GroupSchema<T> = T extends GroupDefinition<infer Schema> ? Schema : never;

	export type PacketFor<T, Context extends Peer> = Context extends "client"
		? ClientPacket<T>
		: Context extends "server"
			? ServerPacket<T>
			: Packet<T>;

	export type RequestFor<Input, Output, Context extends Peer> = Context extends "client"
		? ClientRequest<Input, Output>
		: Context extends "server"
			? ServerRequest<Input, Output>
			: Request<Input, Output>;

	export type DeltaPacketFor<Id, Shape extends ObjectSchema, Context extends Peer> = Context extends "client"
		? ClientDeltaPacket<Id, Shape>
		: Context extends "server"
			? ServerDeltaPacket<Id, Shape>
			: DeltaPacket<Id, Shape>;

	export type Network<T extends NetworkSchema, Context extends Peer = "shared"> = {
		readonly [K in keyof T]: T[K] extends GroupDefinition<any>
			? Network<GroupSchema<T[K]>, Context>
			: T[K] extends DeltaDefinition<any, any>
				? DeltaPacketFor<DeltaEntityId<T[K]>, DeltaSchema<T[K]>, Context>
				: T[K] extends RequestDefinition<any, any>
					? RequestFor<RequestInput<T[K]>, RequestOutput<T[K]>, Context>
					: PacketFor<PacketPayload<T[K]>, Context>;
	};

	export type ClientNetwork<T extends NetworkSchema> = Network<T, "client">;
	export type ServerNetwork<T extends NetworkSchema> = Network<T, "server">;
	export type SharedNetwork<T extends NetworkSchema> = Network<T, "shared">;
	export type BindableNetwork<T extends NetworkSchema> = {
		readonly [K in keyof T]: T[K] extends GroupDefinition<any>
			? BindableNetwork<GroupSchema<T[K]>>
			: T[K] extends DeltaDefinition<any, any>
				? BindableDeltaPacket<DeltaEntityId<T[K]>, DeltaSchema<T[K]>>
				: T[K] extends RequestDefinition<any, any>
					? never
					: BindablePacket<PacketPayload<T[K]>>;
	};

	export interface BasePacket {
		readonly id: number;
		readonly name: string;
		readonly lane: Lane;
		readonly fast: boolean;
	}

	export interface ClientPacket<T = void> extends BasePacket {
		on(this: void, listener: (this: void, ...args: PayloadArgs<T>) => void): Disconnect;
		listen(this: void, listener: (this: void, ...args: PayloadArgs<T>) => void): Disconnect;
		connect(this: void, listener: (this: void, ...args: PayloadArgs<T>) => void): Disconnect;
		once(this: void, listener: (this: void, ...args: PayloadArgs<T>) => void): Disconnect;
		wait(this: void): LuaTuple<PayloadArgs<T>>;
		predict(this: void, listener: (this: void, ...args: PayloadArgs<T>) => void): Disconnect;
		reject(this: void, listener: (this: void, reason: RejectReason) => void): Disconnect;

		onBatch(this: void, listener: (this: void, payloads: BatchPayloads<T>, count: number) => void): Disconnect;
		onBatchCount(this: void, listener: (this: void, count: number) => void): Disconnect;

		send(this: void, ...args: PayloadArgs<T>): void;
		many(this: void, payloads: BatchPayloads<T>): void;
		batch(this: void, payloads: BatchPayloads<T>): void;
		sendMany(this: void, payloads: BatchPayloads<T>): void;
		flushMany(this: void, payloads: BatchPayloads<T>): void;
		sendManyNow(this: void, payloads: BatchPayloads<T>): void;
		batchNow(this: void, payloads: BatchPayloads<T>): void;
	}

	export interface ServerPacket<T = void> extends BasePacket {
		on(this: void, listener: (this: void, player: Player, ...args: PayloadArgs<T>) => void): Disconnect;
		listen(this: void, listener: (this: void, player: Player, ...args: PayloadArgs<T>) => void): Disconnect;
		connect(this: void, listener: (this: void, player: Player, ...args: PayloadArgs<T>) => void): Disconnect;
		once(this: void, listener: (this: void, player: Player, ...args: PayloadArgs<T>) => void): Disconnect;
		wait(this: void): LuaTuple<[player: Player, ...args: PayloadArgs<T>]>;
		reject(this: void, player: Player, reason?: RejectReason): void;

		onBatch(
			this: void,
			listener: (this: void, player: Player, payloads: BatchPayloads<T>, count: number) => void,
		): Disconnect;
		onBatchCount(this: void, listener: (this: void, player: Player, count: number) => void): Disconnect;

		send(this: void, player: Player, ...args: PayloadArgs<T>): void;
		many(this: void, player: Player, payloads: BatchPayloads<T>): void;
		batch(this: void, player: Player, payloads: BatchPayloads<T>): void;
		sendMany(this: void, player: Player, payloads: BatchPayloads<T>): void;
		flushMany(this: void, player: Player, payloads: BatchPayloads<T>): void;
		sendManyNow(this: void, player: Player, payloads: BatchPayloads<T>): void;
		batchNow(this: void, player: Player, payloads: BatchPayloads<T>): void;

		to(this: void, player: Player, ...args: PayloadArgs<T>): void;
		all(this: void, ...args: PayloadArgs<T>): void;
		allMany(this: void, payloads: BatchPayloads<T>): void;
		list(this: void, players: Array<Player>, ...args: PayloadArgs<T>): void;
		listMany(this: void, players: Array<Player>, payloads: BatchPayloads<T>): void;
		except(this: void, player: Player, ...args: PayloadArgs<T>): void;
		exceptMany(this: void, player: Player, payloads: BatchPayloads<T>): void;
		broadcast(this: void, ...args: PayloadArgs<T>): void;
		sendToAll(this: void, ...args: PayloadArgs<T>): void;
		broadcastMany(this: void, payloads: BatchPayloads<T>): void;
		sendManyToAll(this: void, payloads: BatchPayloads<T>): void;
		sendToList(this: void, players: Array<Player>, ...args: PayloadArgs<T>): void;
		sendManyToList(this: void, players: Array<Player>, payloads: BatchPayloads<T>): void;
		sendExcept(this: void, player: Player, ...args: PayloadArgs<T>): void;
		sendManyExcept(this: void, player: Player, payloads: BatchPayloads<T>): void;
	}

	export interface Packet<T = void> extends BasePacket {
		on(this: void, listener: (this: void, ...args: PayloadArgs<T>) => void): Disconnect;
		on(this: void, listener: (this: void, player: Player, ...args: PayloadArgs<T>) => void): Disconnect;
		listen(this: void, listener: (this: void, ...args: PayloadArgs<T>) => void): Disconnect;
		listen(this: void, listener: (this: void, player: Player, ...args: PayloadArgs<T>) => void): Disconnect;
		connect(this: void, listener: (this: void, ...args: PayloadArgs<T>) => void): Disconnect;
		connect(this: void, listener: (this: void, player: Player, ...args: PayloadArgs<T>) => void): Disconnect;
		once(this: void, listener: (this: void, ...args: PayloadArgs<T>) => void): Disconnect;
		once(this: void, listener: (this: void, player: Player, ...args: PayloadArgs<T>) => void): Disconnect;
		wait(this: void): LuaTuple<PayloadArgs<T>> | LuaTuple<[player: Player, ...args: PayloadArgs<T>]>;
		predict(this: void, listener: (this: void, ...args: PayloadArgs<T>) => void): Disconnect;
		reject(this: void, listener: (this: void, reason: RejectReason) => void): Disconnect;
		reject(this: void, player: Player, reason?: RejectReason): void;

		onBatch(this: void, listener: (this: void, payloads: BatchPayloads<T>, count: number) => void): Disconnect;
		onBatch(
			this: void,
			listener: (this: void, player: Player, payloads: BatchPayloads<T>, count: number) => void,
		): Disconnect;
		onBatchCount(this: void, listener: (this: void, count: number) => void): Disconnect;
		onBatchCount(this: void, listener: (this: void, player: Player, count: number) => void): Disconnect;

		send(this: void, ...args: PayloadArgs<T>): void;
		send(this: void, player: Player, ...args: PayloadArgs<T>): void;
		many(this: void, payloads: BatchPayloads<T>): void;
		many(this: void, player: Player, payloads: BatchPayloads<T>): void;
		batch(this: void, payloads: BatchPayloads<T>): void;
		batch(this: void, player: Player, payloads: BatchPayloads<T>): void;
		sendMany(this: void, payloads: BatchPayloads<T>): void;
		sendMany(this: void, player: Player, payloads: BatchPayloads<T>): void;
		flushMany(this: void, payloads: BatchPayloads<T>): void;
		flushMany(this: void, player: Player, payloads: BatchPayloads<T>): void;
		sendManyNow(this: void, payloads: BatchPayloads<T>): void;
		sendManyNow(this: void, player: Player, payloads: BatchPayloads<T>): void;
		batchNow(this: void, payloads: BatchPayloads<T>): void;
		batchNow(this: void, player: Player, payloads: BatchPayloads<T>): void;

		to(this: void, player: Player, ...args: PayloadArgs<T>): void;
		all(this: void, ...args: PayloadArgs<T>): void;
		allMany(this: void, payloads: BatchPayloads<T>): void;
		list(this: void, players: Array<Player>, ...args: PayloadArgs<T>): void;
		listMany(this: void, players: Array<Player>, payloads: BatchPayloads<T>): void;
		except(this: void, player: Player, ...args: PayloadArgs<T>): void;
		exceptMany(this: void, player: Player, payloads: BatchPayloads<T>): void;
		broadcast(this: void, ...args: PayloadArgs<T>): void;
		sendToAll(this: void, ...args: PayloadArgs<T>): void;
		broadcastMany(this: void, payloads: BatchPayloads<T>): void;
		sendManyToAll(this: void, payloads: BatchPayloads<T>): void;
		sendToList(this: void, players: Array<Player>, ...args: PayloadArgs<T>): void;
		sendManyToList(this: void, players: Array<Player>, payloads: BatchPayloads<T>): void;
		sendExcept(this: void, player: Player, ...args: PayloadArgs<T>): void;
		sendManyExcept(this: void, player: Player, payloads: BatchPayloads<T>): void;
	}

	export interface BindablePacket<T = void> extends BasePacket {
		on(this: void, listener: (this: void, ...args: PayloadArgs<T>) => void): Disconnect;
		listen(this: void, listener: (this: void, ...args: PayloadArgs<T>) => void): Disconnect;
		connect(this: void, listener: (this: void, ...args: PayloadArgs<T>) => void): Disconnect;
		once(this: void, listener: (this: void, ...args: PayloadArgs<T>) => void): Disconnect;
		wait(this: void): LuaTuple<PayloadArgs<T>>;
		predict(this: void, listener: (this: void, ...args: PayloadArgs<T>) => void): Disconnect;
		reject(this: void, listener: (this: void, reason: RejectReason) => void): Disconnect;
		reject(this: void, reason?: RejectReason): void;

		onBatch(this: void, listener: (this: void, payloads: BatchPayloads<T>, count: number) => void): Disconnect;
		onBatchCount(this: void, listener: (this: void, count: number) => void): Disconnect;

		send(this: void, ...args: PayloadArgs<T>): void;
		many(this: void, payloads: BatchPayloads<T>): void;
		batch(this: void, payloads: BatchPayloads<T>): void;
		sendMany(this: void, payloads: BatchPayloads<T>): void;
		flushMany(this: void, payloads: BatchPayloads<T>): void;
		sendManyNow(this: void, payloads: BatchPayloads<T>): void;
		batchNow(this: void, payloads: BatchPayloads<T>): void;
		destroy(this: void): void;
	}

	export interface ClientDeltaPacket<Id, Shape extends ObjectSchema>
		extends ClientPacket<DeltaPayload<Id, Shape>> {
		onDelta(this: void, listener: (this: void, entityId: Id, changes: DeltaPatch<Shape>) => void): Disconnect;
		sendDelta(this: void, entityId: Id, changes: DeltaPatch<Shape>): void;
		manyDelta(this: void, deltas: Array<DeltaPayload<Id, Shape>>): void;
		flushManyDelta(this: void, deltas: Array<DeltaPayload<Id, Shape>>): void;
		delta(this: void, entityId: Id, changes: DeltaPatch<Shape>): void;
	}

	export interface ServerDeltaPacket<Id, Shape extends ObjectSchema>
		extends ServerPacket<DeltaPayload<Id, Shape>> {
		onDelta(
			this: void,
			listener: (this: void, player: Player, entityId: Id, changes: DeltaPatch<Shape>) => void,
		): Disconnect;
		sendDelta(this: void, player: Player, entityId: Id, changes: DeltaPatch<Shape>): void;
		sendDelta(this: void, entityId: Id, changes: DeltaPatch<Shape>): void;
		manyDelta(this: void, player: Player, deltas: Array<DeltaPayload<Id, Shape>>): void;
		manyDelta(this: void, deltas: Array<DeltaPayload<Id, Shape>>): void;
		flushManyDelta(this: void, player: Player, deltas: Array<DeltaPayload<Id, Shape>>): void;
		flushManyDelta(this: void, deltas: Array<DeltaPayload<Id, Shape>>): void;
		toDelta(this: void, player: Player, entityId: Id, changes: DeltaPatch<Shape>): void;
		allDelta(this: void, entityId: Id, changes: DeltaPatch<Shape>): void;
		broadcastDelta(this: void, entityId: Id, changes: DeltaPatch<Shape>): void;
		listDelta(this: void, players: Array<Player>, entityId: Id, changes: DeltaPatch<Shape>): void;
		exceptDelta(this: void, player: Player, entityId: Id, changes: DeltaPatch<Shape>): void;
		delta(this: void, player: Player, entityId: Id, changes: DeltaPatch<Shape>): void;
		delta(this: void, entityId: Id, changes: DeltaPatch<Shape>): void;
	}

	export interface DeltaPacket<Id, Shape extends ObjectSchema>
		extends Packet<DeltaPayload<Id, Shape>> {
		onDelta(this: void, listener: (this: void, entityId: Id, changes: DeltaPatch<Shape>) => void): Disconnect;
		onDelta(
			this: void,
			listener: (this: void, player: Player, entityId: Id, changes: DeltaPatch<Shape>) => void,
		): Disconnect;
		sendDelta(this: void, entityId: Id, changes: DeltaPatch<Shape>): void;
		sendDelta(this: void, player: Player, entityId: Id, changes: DeltaPatch<Shape>): void;
		manyDelta(this: void, deltas: Array<DeltaPayload<Id, Shape>>): void;
		manyDelta(this: void, player: Player, deltas: Array<DeltaPayload<Id, Shape>>): void;
		flushManyDelta(this: void, deltas: Array<DeltaPayload<Id, Shape>>): void;
		flushManyDelta(this: void, player: Player, deltas: Array<DeltaPayload<Id, Shape>>): void;
		toDelta(this: void, player: Player, entityId: Id, changes: DeltaPatch<Shape>): void;
		allDelta(this: void, entityId: Id, changes: DeltaPatch<Shape>): void;
		broadcastDelta(this: void, entityId: Id, changes: DeltaPatch<Shape>): void;
		listDelta(this: void, players: Array<Player>, entityId: Id, changes: DeltaPatch<Shape>): void;
		exceptDelta(this: void, player: Player, entityId: Id, changes: DeltaPatch<Shape>): void;
		delta(this: void, entityId: Id, changes: DeltaPatch<Shape>): void;
		delta(this: void, player: Player, entityId: Id, changes: DeltaPatch<Shape>): void;
	}

	export interface BindableDeltaPacket<Id, Shape extends ObjectSchema>
		extends BindablePacket<DeltaPayload<Id, Shape>> {
		onDelta(this: void, listener: (this: void, entityId: Id, changes: DeltaPatch<Shape>) => void): Disconnect;
		sendDelta(this: void, entityId: Id, changes: DeltaPatch<Shape>): void;
		manyDelta(this: void, deltas: Array<DeltaPayload<Id, Shape>>): void;
		flushManyDelta(this: void, deltas: Array<DeltaPayload<Id, Shape>>): void;
		delta(this: void, entityId: Id, changes: DeltaPatch<Shape>): void;
	}

	export interface InvokeOptions {
		timeout?: number;
	}

	export type RequestArgs<T> = T extends void
		? [options?: InvokeOptions]
		: [payload: T, options?: InvokeOptions];

	export interface BaseRequest<Input = void, Output = void> {
		readonly name: string;
	}

	export interface ClientRequest<Input = void, Output = void> extends BaseRequest<Input, Output> {
		readonly request: ClientPacket<{ requestId: number; value: Input }>;
		readonly response: ClientPacket<{
			requestId: number;
			result: Variant<"Ok", Output> | Variant<"Err", string>;
		}>;

		handle(this: void, listener: (this: void, ...args: PayloadArgs<Input>) => Output): Disconnect;
		respond(this: void, listener: (this: void, ...args: PayloadArgs<Input>) => Output): Disconnect;

		invoke(this: void, ...args: RequestArgs<Input>): LuaTuple<[ok: boolean, result: Output | string]>;
		call(this: void, ...args: RequestArgs<Input>): LuaTuple<[ok: boolean, result: Output | string]>;
		promise(this: void, ...args: RequestArgs<Input>): PromiseResult<Output>;
	}

	export interface ServerRequest<Input = void, Output = void> extends BaseRequest<Input, Output> {
		readonly request: ServerPacket<{ requestId: number; value: Input }>;
		readonly response: ServerPacket<{
			requestId: number;
			result: Variant<"Ok", Output> | Variant<"Err", string>;
		}>;

		handle(this: void, listener: (this: void, player: Player, ...args: PayloadArgs<Input>) => Output): Disconnect;
		respond(this: void, listener: (this: void, player: Player, ...args: PayloadArgs<Input>) => Output): Disconnect;

		invoke(this: void, player: Player, ...args: RequestArgs<Input>): LuaTuple<[ok: boolean, result: Output | string]>;
		call(this: void, player: Player, ...args: RequestArgs<Input>): LuaTuple<[ok: boolean, result: Output | string]>;
		promise(this: void, player: Player, ...args: RequestArgs<Input>): PromiseResult<Output>;
	}

	export interface Request<Input = void, Output = void> extends BaseRequest<Input, Output> {
		readonly request: Packet<{ requestId: number; value: Input }>;
		readonly response: Packet<{
			requestId: number;
			result: Variant<"Ok", Output> | Variant<"Err", string>;
		}>;

		handle(this: void, listener: (this: void, ...args: PayloadArgs<Input>) => Output): Disconnect;
		handle(this: void, listener: (this: void, player: Player, ...args: PayloadArgs<Input>) => Output): Disconnect;
		respond(this: void, listener: (this: void, ...args: PayloadArgs<Input>) => Output): Disconnect;
		respond(this: void, listener: (this: void, player: Player, ...args: PayloadArgs<Input>) => Output): Disconnect;

		invoke(this: void, ...args: RequestArgs<Input>): LuaTuple<[ok: boolean, result: Output | string]>;
		invoke(this: void, player: Player, ...args: RequestArgs<Input>): LuaTuple<[ok: boolean, result: Output | string]>;
		call(this: void, ...args: RequestArgs<Input>): LuaTuple<[ok: boolean, result: Output | string]>;
		call(this: void, player: Player, ...args: RequestArgs<Input>): LuaTuple<[ok: boolean, result: Output | string]>;
		promise(this: void, ...args: RequestArgs<Input>): PromiseResult<Output>;
		promise(this: void, player: Player, ...args: RequestArgs<Input>): PromiseResult<Output>;
	}

	export interface RequestConfig<Input extends SchemaValue = "none", Output extends SchemaValue = "none">
		extends PacketOptions {
		input?: Input;
		payload?: Input;
		output?: Output;
		response?: Output;
		requestId?: number;
		responseId?: number;
		requestName?: string;
		responseName?: string;
		timeout?: number;
	}

	export type RequestConfigInput<T> = T extends { input: infer Input }
		? Infer<Input>
		: T extends { payload: infer Payload }
			? Infer<Payload>
			: void;

	export type RequestConfigOutput<T> = T extends { output: infer Output }
		? Infer<Output>
		: T extends { response: infer Response }
			? Infer<Response>
			: void;

	export interface AuditPacket {
		name: string;
		id: number;
		lane: Lane;
		payload: string;
		packed: boolean;
		explicitId: boolean;
	}

	export interface AuditReport {
		ok: boolean;
		version: string;
		packets: Array<AuditPacket>;
		warnings: Array<string>;
		errors: Array<string>;
	}

	export interface StatsSnapshot {
		sentPackets: number;
		receivedPackets: number;
		sentBatches: number;
		receivedBatches: number;
		sentFrameBatches: number;
		receivedFrameBatches: number;
		sentPackedBatches: number;
		receivedPackedBatches: number;
		sentBytes: number;
		receivedBytes: number;
		sentPackedBytes: number;
		receivedPackedBytes: number;
		droppedPackets: number;
		warnings: number;
		queuedPackets: number;
		[key: string]: number;
	}

	export interface ConfigureOptions {
		validate?: boolean;
		stats?: boolean;
		earlyQueue?: boolean;
		promise?: unknown;
	}

	export type Middleware = (
		this: void,
		packetName: string,
		sender: Player | undefined,
		payload: unknown,
	) => boolean | void;

	export interface BoundedStringGuard extends TypeGuard<string> {
		(this: void, minLength?: number, maxLength?: number): TypeGuard<string>;
	}

	export interface BoundedBufferGuard extends TypeGuard<buffer> {
		(this: void, minLength?: number, maxLength?: number): TypeGuard<buffer>;
	}

	export interface QuantizedVector3Guard extends TypeGuard<Vector3> {
		(this: void, scale?: number): TypeGuard<Vector3>;
	}

	export interface QuantizedCFrameGuard extends TypeGuard<CFrame> {
		(this: void, scale?: number): TypeGuard<CFrame>;
	}

	export interface TypeRegistry {
		readonly any: TypeGuard<any>;
		readonly unknown: TypeGuard<unknown>;
		readonly bool: TypeGuard<boolean>;
		readonly boolean: TypeGuard<boolean>;
		readonly boolean8: TypeGuard<boolean>;
		readonly Boolean8: TypeGuard<boolean>;
		readonly boolean1: TypeGuard<Boolean1Payload>;
		readonly Boolean1: TypeGuard<Boolean1Payload>;
		readonly string: BoundedStringGuard;
		readonly str: BoundedStringGuard;
		readonly none: TypeGuard<void>;
		readonly nil: TypeGuard<void>;
		readonly nil_: TypeGuard<void>;
		readonly u4: TypeGuard<U4Payload>;
		readonly U4: TypeGuard<U4Payload>;
		readonly u8: TypeGuard<number>;
		readonly U8: TypeGuard<number>;
		readonly uint8: TypeGuard<number>;
		readonly u16: TypeGuard<number>;
		readonly U16: TypeGuard<number>;
		readonly uint16: TypeGuard<number>;
		readonly u24: TypeGuard<number>;
		readonly uint24: TypeGuard<number>;
		readonly U24: TypeGuard<number>;
		readonly u32: TypeGuard<number>;
		readonly U32: TypeGuard<number>;
		readonly uint32: TypeGuard<number>;
		readonly playerId: TypeGuard<number> & ((this: void) => TypeGuard<number>);
		readonly playerid: TypeGuard<number> & ((this: void) => TypeGuard<number>);
		readonly PlayerId: TypeGuard<number> & ((this: void) => TypeGuard<number>);
		readonly entityId: TypeGuard<number> & ((this: void) => TypeGuard<number>);
		readonly entityid: TypeGuard<number> & ((this: void) => TypeGuard<number>);
		readonly EntityId: TypeGuard<number> & ((this: void) => TypeGuard<number>);
		readonly s8: TypeGuard<number>;
		readonly S8: TypeGuard<number>;
		readonly i8: TypeGuard<number>;
		readonly int8: TypeGuard<number>;
		readonly s16: TypeGuard<number>;
		readonly S16: TypeGuard<number>;
		readonly i16: TypeGuard<number>;
		readonly int16: TypeGuard<number>;
		readonly s24: TypeGuard<number>;
		readonly S24: TypeGuard<number>;
		readonly i24: TypeGuard<number>;
		readonly int24: TypeGuard<number>;
		readonly s32: TypeGuard<number>;
		readonly S32: TypeGuard<number>;
		readonly i32: TypeGuard<number>;
		readonly int32: TypeGuard<number>;
		readonly f16: TypeGuard<number>;
		readonly float16: TypeGuard<number>;
		readonly F16: TypeGuard<number>;
		readonly f24: TypeGuard<number>;
		readonly float24: TypeGuard<number>;
		readonly F24: TypeGuard<number>;
		readonly f32: TypeGuard<number>;
		readonly F32: TypeGuard<number>;
		readonly float32: TypeGuard<number>;
		readonly float: TypeGuard<number>;
		readonly f64: TypeGuard<number>;
		readonly F64: TypeGuard<number>;
		readonly float64: TypeGuard<number>;
		readonly double: TypeGuard<number>;
		readonly number: TypeGuard<number>;
		readonly vec2: TypeGuard<Vector2>;
		readonly vector2: TypeGuard<Vector2>;
		readonly Vector2: TypeGuard<Vector2>;
		readonly vector2s16: TypeGuard<Vector2>;
		readonly Vector2S16: TypeGuard<Vector2>;
		readonly vector2f24: TypeGuard<Vector2>;
		readonly Vector2F24: TypeGuard<Vector2>;
		readonly vector2f32: TypeGuard<Vector2>;
		readonly Vector2F32: TypeGuard<Vector2>;
		readonly vec3: TypeGuard<Vector3>;
		readonly vector3: TypeGuard<Vector3>;
		readonly Vector3: TypeGuard<Vector3>;
		readonly vector3s16: TypeGuard<Vector3>;
		readonly Vector3S16: TypeGuard<Vector3>;
		readonly vector3f24: TypeGuard<Vector3>;
		readonly Vector3F24: TypeGuard<Vector3>;
		readonly vector3f32: TypeGuard<Vector3>;
		readonly Vector3F32: TypeGuard<Vector3>;
		readonly qvec3_i16: QuantizedVector3Guard;
		readonly qtransform_yaw_i16: QuantizedCFrameGuard;
		readonly qnormal_i16: TypeGuard<Vector3>;
		readonly qyaw_u8: TypeGuard<number>;
		readonly qangle_u16: TypeGuard<number>;
		readonly qalpha_u8: TypeGuard<number>;
		readonly cframe: TypeGuard<CFrame>;
		readonly CFrame: TypeGuard<CFrame>;
		readonly cframef24u8: TypeGuard<CFrame>;
		readonly CFrameF24U8: TypeGuard<CFrame>;
		readonly numberrange: TypeGuard<NumberRange>;
		readonly NumberRange: TypeGuard<NumberRange>;
		readonly numbersequence: TypeGuard<NumberSequence>;
		readonly NumberSequence: TypeGuard<NumberSequence>;
		readonly color3: TypeGuard<Color3>;
		readonly Color3: TypeGuard<Color3>;
		readonly colorsequence: TypeGuard<ColorSequence>;
		readonly ColorSequence: TypeGuard<ColorSequence>;
		readonly region3: TypeGuard<Region3>;
		readonly Region3: TypeGuard<Region3>;
		readonly rect: TypeGuard<Rect>;
		readonly Rect: TypeGuard<Rect>;
		readonly brickcolor: TypeGuard<BrickColor>;
		readonly BrickColor: TypeGuard<BrickColor>;
		readonly udim: TypeGuard<UDim>;
		readonly UDim: TypeGuard<UDim>;
		readonly udim2: TypeGuard<UDim2>;
		readonly UDim2: TypeGuard<UDim2>;
		readonly player: TypeGuard<Player> & ((this: void) => TypeGuard<Player>);
		readonly character: TypeGuard<Model> & ((this: void) => TypeGuard<Model>);
		readonly buffer: BoundedBufferGuard;
		readonly buff: BoundedBufferGuard;

		resolve<T extends SchemaValue>(this: void, spec: T): TypeGuard<Infer<T>>;
		object<const T extends ObjectSchema>(this: void, shape: T): TypeGuard<{ [K in keyof T]: Infer<T[K]> }>;
		struct<const T extends ObjectSchema>(this: void, shape: T): TypeGuard<{ [K in keyof T]: Infer<T[K]> }>;
		array<const T extends SchemaValue>(
			this: void,
			itemSpec: T,
			minLength?: number,
			maxLength?: number,
		): TypeGuard<Array<Infer<T>>>;
		map<const K extends SchemaValue, const V extends SchemaValue>(
			this: void,
			keySpec: K,
			valueSpec: V,
			minLength?: number,
			maxLength?: number,
		): TypeGuard<MapPayload<InferMapKey<K>, Infer<V>>>;
		optional<const T extends SchemaValue>(this: void, itemSpec: T): TypeGuard<Infer<T> | undefined>;
		ref<const Kind extends string>(this: void, kind: Kind): TypeGuard<Instance>;
		entity<const Kind extends string = "Entity">(this: void, kind?: Kind): TypeGuard<Instance>;
		delta<const Shape extends ObjectSchema, const Id extends SchemaValue = "u32">(
			this: void,
			shape: Shape,
			entityIdSpec?: Id,
		): TypeGuard<DeltaPayload<Infer<Id>, Shape>>;
		instance<T extends Instance = Instance>(this: void, className?: string): TypeGuard<T>;
		inst<T extends Instance = Instance>(this: void, className?: string): TypeGuard<T>;
		enum<const T extends ReadonlyArray<unknown>>(this: void, values: T): TypeGuard<T[number]>;
		flags<const T extends readonly string[]>(this: void, values: T): TypeGuard<number>;
		variant<const T extends Record<string, SchemaValue>>(this: void, variants: T): TypeGuard<InferVariantCases<T>>;
		literal<const T>(this: void, expected: T): TypeGuard<T>;
		tuple<const T extends readonly SchemaValue[]>(
			this: void,
			...items: T
		): TypeGuard<InferTuple<T>>;
	}

	export interface InstanceReferenceRegistry {
		register(this: void, kind: string, instance: Instance, id: number): Disconnect;
		unregister(this: void, kind: string, target: Instance | number): void;
		id(this: void, kind: string, instance: Instance): number | undefined;
		getId(this: void, kind: string, instance: Instance): number | undefined;
		resolve(this: void, kind: string, id: number): Instance | undefined;
		clear(this: void, kind?: string): void;
	}

	export interface JoinSyncOptions {
		name?: string;
		defer?: boolean;
	}

	export type JoinSyncHandlers<Stage extends string> =
		| Partial<Record<Stage, (this: void, player: Player, stage: Stage) => void>>
		| ((this: void, player: Player, stage: Stage) => void);

	export interface JoinSyncPipeline<Stage extends string = string> {
		readonly name: string;
		readonly stages: ReadonlyArray<Stage>;
		start(this: void, player: Player, handlers?: JoinSyncHandlers<Stage>): void;
		run(this: void, player: Player, handlers?: JoinSyncHandlers<Stage>): void;
		sync(this: void, player: Player, handlers?: JoinSyncHandlers<Stage>): void;
		onStage(this: void, listener: (this: void, stage: Stage) => void): Disconnect;
		onDone(this: void, listener: (this: void) => void): Disconnect;
		wait(this: void): void;
		isDone(this: void): boolean;
		hasCompleted(this: void, stage: Stage): boolean;
		reset(this: void): void;
	}

	export interface JoinSyncRegistry {
		define<const Stages extends readonly string[]>(
			this: void,
			stages: Stages,
			options?: JoinSyncOptions,
		): JoinSyncPipeline<Stages[number]>;
		receive(this: void, payload: unknown): void;
	}

	export interface LayerRegistry {
		set(this: void, target: unknown, layer: string): void;
		get(this: void, target: unknown): string | undefined;
		clear(this: void, target?: unknown): void;
		same(this: void, first: unknown, second: unknown): boolean;
		playersFor(this: void, target: unknown, candidates?: Array<Player>): Array<Player>;
	}

	export type RelevanceRule = (this: void, player: Player, entity: unknown, context?: unknown) => boolean;
	export interface RelevanceRegistry {
		rule(this: void, name: string, callback: RelevanceRule): Disconnect;
		remove(this: void, name: string): void;
		clear(this: void): void;
		check(this: void, player: Player, entity: unknown, context?: unknown): boolean;
		playersFor(this: void, entity: unknown, context?: unknown, candidates?: Array<Player>): Array<Player>;
	}

	export interface Replica<Shape extends ObjectSchema> {
		Set<K extends keyof DeltaShape<Shape> & string>(this: void, field: K, value: DeltaShape<Shape>[K]): void;
		Patch(this: void, patch: DeltaPatch<Shape>): void;
		Flush(this: void): void;
		Destroy(this: void): void;
	}

	export interface ReplicatorConfig<Shape extends ObjectSchema, Id extends SchemaValue = "u32">
		extends PacketConfigOptions {
		name?: string;
		packetId?: number;
		entityId?: Id;
		entityIdSpec?: Id;
		idSpec?: Id;
		state: Shape;
	}

	export interface StateReplicator<Id, Shape extends ObjectSchema> {
		readonly packet: DeltaPacket<Id, Shape>;
		readonly Packet: DeltaPacket<Id, Shape>;
		Track(this: void, entityId: Id, state?: DeltaShape<Shape>): Replica<Shape>;
		Untrack(this: void, entityId: Id): void;
		Set<K extends keyof DeltaShape<Shape> & string>(
			this: void,
			entityId: Id,
			field: K,
			value: DeltaShape<Shape>[K],
		): void;
		Set(this: void, entityId: Id, patch: DeltaPatch<Shape>): void;
		Get(this: void, entityId: Id): DeltaShape<Shape> | undefined;
		SetInterest(this: void, player: Player, entityId: Id, interest: unknown): void;
		Flush(this: void, entityId?: Id): void;
	}

	export interface TagReplication<Id = number> {
		readonly packet: Packet<{ entityId: Id; tagged: boolean }>;
		readonly Packet: Packet<{ entityId: Id; tagged: boolean }>;
		Sync(this: void, player?: Player): void;
		Has(this: void, entityId: Id): boolean;
		OnChanged(this: void, listener: (this: void, entityId: Id, tagged: boolean) => void): Disconnect;
		Destroy(this: void): void;
	}

	export interface TagReplicationOptions<Id extends SchemaValue = "u32"> extends PacketConfigOptions {
		entityId?: Id;
		entityIdSpec?: Id;
		idSpec?: Id;
		kind?: string;
		attribute?: string;
		idOf?: (this: void, instance: Instance) => Infer<Id> | undefined;
	}

	export interface TagsRegistry {
		replicate<const Id extends SchemaValue = "u32">(
			this: void,
			tag: string,
			options?: TagReplicationOptions<Id>,
		): TagReplication<Infer<Id>>;
	}

	export interface AttributeReplication<Id, Shape extends ObjectSchema> {
		readonly packet: DeltaPacket<Id, Shape>;
		readonly Packet: DeltaPacket<Id, Shape>;
		Sync(this: void, player?: Player): void;
		Get(this: void, entityId: Id): DeltaShape<Shape> | undefined;
		OnChanged(
			this: void,
			listener: (this: void, entityId: Id, changes: DeltaPatch<Shape>, instance?: Instance) => void,
		): Disconnect;
		Destroy(this: void): void;
	}

	export interface AttributeTrackOptions<Id extends SchemaValue = "u32"> extends PacketConfigOptions {
		entityId?: Id;
		entityIdSpec?: Id;
		idSpec?: Id;
		kind?: string;
		idAttribute?: string;
		apply?: boolean;
		idOf?: (this: void, instance: Instance) => Infer<Id> | undefined;
	}

	export interface AttributesRegistry {
		track<const Shape extends ObjectSchema, const Id extends SchemaValue = "u32">(
			this: void,
			instance: Instance,
			schema: Shape,
			options?: AttributeTrackOptions<Id>,
		): AttributeReplication<Infer<Id>, Shape>;
	}

	export interface ShardOptions {
		topic?: string;
		shardId?: string;
		role?: string;
		validate?: boolean;
		defer?: boolean;
		echo?: boolean;
		autoStart?: boolean;
		dedupe?: boolean;
		memoryStore?: boolean;
		dedupeTtl?: number;
	}

	export interface ShardBridge<T extends Record<string, SchemaValue>> {
		Start(this: void): void;
		Stop(this: void): void;
		Send<K extends keyof T & string>(this: void, packetName: K, payload: Infer<T[K]>, targetShard?: string): void;
		On<K extends keyof T & string>(
			this: void,
			packetName: K,
			listener: (this: void, payload: Infer<T[K]>, source?: string, envelope?: unknown) => void,
		): Disconnect;
		start(this: void): void;
		stop(this: void): void;
		send<K extends keyof T & string>(this: void, packetName: K, payload: Infer<T[K]>, targetShard?: string): void;
		publish<K extends keyof T & string>(this: void, packetName: K, payload: Infer<T[K]>, targetShard?: string): void;
		on<K extends keyof T & string>(
			this: void,
			packetName: K,
			listener: (this: void, payload: Infer<T[K]>, source?: string, envelope?: unknown) => void,
		): Disconnect;
		connect<K extends keyof T & string>(
			this: void,
			packetName: K,
			listener: (this: void, payload: Infer<T[K]>, source?: string, envelope?: unknown) => void,
		): Disconnect;
	}

	export interface ShardRegistry {
		bridge<const T extends Record<string, SchemaValue>>(
			this: void,
			name: string,
			schema: T,
			options?: ShardOptions,
		): ShardBridge<T>;
		channel<const T extends Record<string, SchemaValue>>(
			this: void,
			name: string,
			schema: T,
			options?: ShardOptions,
		): ShardBridge<T>;
	}

	export interface Api {
		<const T extends NetworkSchema, Context extends Peer = "shared">(
			this: void,
			schema: T,
			options?: BuildOptions,
		): Network<T, Context>;

		group<const T extends NetworkSchema>(this: void, schema: T): GroupDefinition<T>;
		with<const T extends SchemaValue>(
			this: void,
			payload: T,
			options?: PacketConfigOptions,
		): PacketDefinition<Infer<T>>;
		request<const Input extends SchemaValue, const Output extends SchemaValue>(
			this: void,
			input: Input,
			output: Output,
			options?: PacketConfigOptions & { timeout?: number; requestId?: number; responseId?: number },
		): RequestDefinition<Infer<Input>, Infer<Output>>;
		request<const Config extends RequestConfig<any, any>>(
			this: void,
			config: Config,
		): RequestDefinition<RequestConfigInput<Config>, RequestConfigOutput<Config>>;
		reliable<const T extends SchemaValue>(
			this: void,
			payload: T,
			options?: PacketConfigOptions,
		): PacketDefinition<Infer<T>>;
		unreliable<const T extends SchemaValue>(
			this: void,
			payload: T,
			options?: PacketConfigOptions,
		): PacketDefinition<Infer<T>>;
		fast<const T extends SchemaValue>(this: void, payload: T, options?: PacketConfigOptions): PacketDefinition<Infer<T>>;
		instant<const T extends SchemaValue>(
			this: void,
			payload: T,
			options?: PacketConfigOptions,
		): PacketDefinition<Infer<T>>;
		direct<const T extends SchemaValue>(
			this: void,
			payload: T,
			options?: PacketConfigOptions,
		): PacketDefinition<Infer<T>>;
		delta<const Shape extends ObjectSchema, const Id extends SchemaValue = "u32">(
			this: void,
			shape: Shape,
			options?: DeltaOptions<Id>,
		): DeltaDefinition<Infer<Id>, Shape>;
		transaction<const T extends SchemaValue>(
			this: void,
			payload: T,
			options?: TransactionOptions<Infer<T>>,
		): PacketDefinition<Infer<T>>;
		transaction<const T extends SchemaValue>(
			this: void,
			name: string,
			payload: T,
			options?: TransactionOptions<Infer<T>>,
		): Packet<Infer<T>>;
		replicator<const Shape extends ObjectSchema, const Id extends SchemaValue = "u32">(
			this: void,
			config: ReplicatorConfig<Shape, Id>,
			options?: PacketConfigOptions,
		): StateReplicator<Infer<Id>, Shape>;
		shard<const T extends Record<string, SchemaValue>>(
			this: void,
			name: string,
			schema: T,
			options?: ShardOptions,
		): ShardBridge<T>;
		packet(this: void, name: string): Packet<void>;
		packet<const T extends SchemaValue>(
			this: void,
			name: string,
			payload: T,
			options?: DirectPacketOptions,
		): Packet<Infer<T>>;
		case<const K extends string, const T>(this: void, kind: K, payload: T): Variant<K, T>;
		variant<const K extends string, const T>(this: void, kind: K, payload: T): Variant<K, T>;
		use(this: void, middleware: Middleware): Disconnect;
		configure(this: void, options?: ConfigureOptions): void;
		audit<const T extends NetworkSchema>(this: void, schema: T, options?: AuditOptions): AuditReport;
		isReady(this: void): boolean;
		flush(this: void): void;
		stats(this: void): StatsSnapshot;
		resetStats(this: void): void;
		client<const T extends NetworkSchema>(this: void, schema: T, options?: BuildOptions): ClientNetwork<T>;
		server<const T extends NetworkSchema>(this: void, schema: T, options?: BuildOptions): ServerNetwork<T>;
		shared<const T extends NetworkSchema>(this: void, schema: T, options?: BuildOptions): SharedNetwork<T>;
		bindable<const T extends NetworkSchema>(this: void, schema: T): BindableNetwork<T>;
		schema<const T extends NetworkSchema, Context extends Peer = "shared">(
			this: void,
			schema: T,
			options?: BuildOptions,
		): Network<T, Context>;
		network<const T extends NetworkSchema, Context extends Peer = "shared">(
			this: void,
			schema: T,
			options?: BuildOptions,
		): Network<T, Context>;

		readonly t: TypeRegistry;
		readonly types: TypeRegistry;
		readonly Registry: InstanceReferenceRegistry;
		readonly JoinSync: JoinSyncRegistry;
		readonly Layer: LayerRegistry;
		readonly Relevance: RelevanceRegistry;
		readonly Tags: TagsRegistry;
		readonly Attributes: AttributesRegistry;
		readonly Shard: ShardRegistry;
		readonly ready: boolean;
		readonly version: string;
	}
}

declare const VNet: VNet.Api;
export = VNet;
