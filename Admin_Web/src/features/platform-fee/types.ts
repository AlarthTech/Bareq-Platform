export interface PlatformFeeResponse {
  fixedPlatformFeeAmount: number;
}

export interface UpdatePlatformFeeRequest {
  fixedPlatformFeeAmount: number;
}

export interface UpdatePlatformFeeResponse {
  success: boolean;
  fixedPlatformFeeAmount: number;
}
