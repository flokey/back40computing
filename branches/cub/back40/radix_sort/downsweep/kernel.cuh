/******************************************************************************
 * 
 * Copyright (c) 2011-2012, Duane Merrill.  All rights reserved.
 * Copyright (c) 2011-2012, NVIDIA CORPORATION.  All rights reserved.
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License. 
 * 
 ******************************************************************************/
/******************************************************************************
 * Radix sort downsweep scan kernel (scatter into bins)
 ******************************************************************************/

#pragma once

#include <cub/cub.cuh>

#include <back40/radix_sort/downsweep/cta.cuh>

namespace back40 {
namespace radix_sort {
namespace downsweep {


/**
 * Radix sort downsweep scan kernel entry point
 */
template <
	typename KernelPolicy,
	typename SizeT,
	typename KeyType,
	typename ValueType,
	typename IngressOp,
	typename EgressOp>
__launch_bounds__ (KernelPolicy::THREADS, KernelPolicy::MIN_CTA_OCCUPANCY)
__global__ 
void Kernel(
	SizeT 		*d_spine,
	KeyType 	*d_keys0,
	KeyType 	*d_keys1,
	ValueType 	*d_values0,
	ValueType 	*d_values1,
	IngressOp	ingress_op,
	EgressOp	egress_op,
	util::CtaWorkDistribution<SizeT> work_decomposition)
{
	// CTA abstraction type
	typedef Cta<KernelPolicy, SizeT, KeyType, ValueType> Cta;

	// Shared memory pool
	__shared__ typename Cta::SmemStorage smem_storage;

	if (threadIdx.x == 0)
	{
		// Determine our threadblock's work range
		work_decomposition.GetCtaWorkLimits(
			smem_storage.work_limits,
			KernelPolicy::LOG_TILE_ELEMENTS);

		smem_storage.tex_offset =
			smem_storage.work_limits.offset / Cta::ELEMENTS_PER_TEX;

		smem_storage.tex_offset_limit =
			smem_storage.work_limits.guarded_offset / Cta::ELEMENTS_PER_TEX;
	}

	// Sync to acquire work limits
	__syncthreads();

	Cta cta(
		smem_storage,
		d_keys0,
		d_keys1,
		d_values0,
		d_values1,
		d_spine);

	cta.ProcessWorkRange(smem_storage.work_limits);
}



} // namespace downsweep
} // namespace radix_sort
} // namespace back40
